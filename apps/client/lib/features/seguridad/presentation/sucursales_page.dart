import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'sucursal_form_sheet.dart';

class SucursalesPage extends ConsumerStatefulWidget {
	const SucursalesPage({super.key});

	@override
	ConsumerState<SucursalesPage> createState() => _SucursalesPageState();
}

class _SucursalesPageState extends ConsumerState<SucursalesPage> {
	late Future<List<dynamic>> _future;

	@override
	void initState() {
		super.initState();
		_future = _load();
	}

	Future<List<dynamic>> _load() {
		return ref.read(apiClientProvider).getList('sucursales');
	}

	void _refresh() => setState(() => _future = _load());

	bool _tieneDerecho(String codigo) {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.tieneDerecho(codigo) ?? false;
	}

	Future<void> _crear() async {
		final ok = await showSucursalForm(context, ref);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Planta creada')),
			);
		}
	}

	Future<void> _editar(Map<String, dynamic> sucursal) async {
		final ok = await showSucursalForm(context, ref, sucursal: sucursal);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Planta actualizada')),
			);
		}
	}

	Future<void> _desactivar(Map<String, dynamic> sucursal) async {
		final nombre = sucursal['nombre'] as String? ?? '';
		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Desactivar planta'),
				content: Text('¿Desactivar "$nombre"? Los usuarios no perderán datos.'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Desactivar'),
					),
				],
			),
		);

		if (confirmado != true) return;

		try {
			await ref.read(apiClientProvider).deleteJson('sucursales/${sucursal['id']}');
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Planta "$nombre" desactivada')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final puedeAgregar = _tieneDerecho('configuracion.sucursales.agregar');
		final puedeModificar = _tieneDerecho('configuracion.sucursales.agregar');
		final puedeBorrar = _tieneDerecho('configuracion.sucursales.borrar');

		return Column(
			children: [
				_PageHeader(
					title: 'Plantas',
					onRefresh: _refresh,
					onAdd: puedeAgregar ? _crear : null,
				),
				Expanded(
					child: FutureBuilder<List<dynamic>>(
						future: _future,
						builder: (context, snapshot) {
							if (snapshot.connectionState == ConnectionState.waiting) {
								return const Center(child: CircularProgressIndicator());
							}
							if (snapshot.hasError) {
								return Center(child: Text(snapshot.error.toString()));
							}

							final sucursales = snapshot.data ?? [];
							return ListView.separated(
								padding: const EdgeInsets.all(20),
								itemCount: sucursales.length,
								separatorBuilder: (_, __) => const SizedBox(height: 8),
								itemBuilder: (context, index) {
									final item = sucursales[index] as Map<String, dynamic>;
									final count =
											(item['_count'] as Map<String, dynamic>?)?['usuarios'] ?? 0;
									final activa = item['activa'] as bool? ?? false;

									return Material(
										color: Theme.of(context).colorScheme.surface,
										borderRadius: BorderRadius.circular(16),
										child: ListTile(
											contentPadding: const EdgeInsets.symmetric(
												horizontal: 16,
												vertical: 8,
											),
											onTap: puedeModificar ? () => _editar(item) : null,
											leading: const Icon(Icons.apartment_rounded),
											title: Text(
												item['nombre'] as String,
												style: const TextStyle(fontWeight: FontWeight.w600),
											),
											subtitle: Text(
												'Código: ${item['codigo']} · $count usuarios · ${activa ? 'Activa' : 'Inactiva'}',
											),
											trailing: isCompactLayout(context)
													? (puedeBorrar && activa
															? IconButton(
																	tooltip: 'Desactivar',
																	onPressed: () => _desactivar(item),
																	icon: const Icon(Icons.block_outlined, size: 20),
																)
															: null)
													: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Chip(
														label: Text(activa ? 'Activa' : 'Inactiva'),
														backgroundColor: activa
																? AppColors.success.withValues(alpha: 0.15)
																: Colors.grey.withValues(alpha: 0.15),
													),
													if (puedeBorrar && activa)
														IconButton(
															tooltip: 'Desactivar',
															onPressed: () => _desactivar(item),
															icon: const Icon(Icons.block_outlined, size: 20),
														),
												],
											),
										),
									);
								},
							);
						},
					),
				),
			],
		);
	}
}

class _PageHeader extends StatelessWidget {
	const _PageHeader({
		required this.title,
		required this.onRefresh,
		this.onAdd,
	});

	final String title;
	final VoidCallback onRefresh;
	final VoidCallback? onAdd;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 64,
			padding: const EdgeInsets.symmetric(horizontal: 20),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				border: Border(
					bottom: BorderSide(
						color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
					),
				),
			),
			child: Row(
				children: [
					Text(
						title,
						style: Theme.of(context).textTheme.titleLarge?.copyWith(
									fontWeight: FontWeight.w700,
								),
					),
					const Spacer(),
					if (onAdd != null)
						FilledButton.tonalIcon(
							onPressed: onAdd,
							icon: const Icon(Icons.add_business_outlined, size: 18),
							label: const Text('Nueva'),
						),
					if (onAdd != null) const SizedBox(width: 8),
					IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
				],
			),
		);
	}
}
