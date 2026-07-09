import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'perfil_form_sheet.dart';

class PerfilesPage extends ConsumerStatefulWidget {
	const PerfilesPage({super.key});

	@override
	ConsumerState<PerfilesPage> createState() => _PerfilesPageState();
}

class _PerfilesPageState extends ConsumerState<PerfilesPage> {
	late Future<List<dynamic>> _future;

	@override
	void initState() {
		super.initState();
		_future = _load();
	}

	Future<List<dynamic>> _load() {
		return ref.read(apiClientProvider).getList('perfiles');
	}

	void _refresh() => setState(() => _future = _load());

	bool _tieneDerecho(String codigo) {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.tieneDerecho(codigo) ?? false;
	}

	Future<void> _crear() async {
		final ok = await showPerfilForm(context, ref);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Perfil creado')),
			);
		}
	}

	Future<void> _editar(Map<String, dynamic> perfil) async {
		final ok = await showPerfilForm(context, ref, perfil: perfil);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Perfil actualizado')),
			);
		}
	}

	Future<void> _desactivar(Map<String, dynamic> perfil) async {
		final nombre = perfil['nombre'] as String? ?? '';
		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Desactivar perfil'),
				content: Text('¿Desactivar el perfil "$nombre"?'),
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
			await ref.read(apiClientProvider).deleteJson('perfiles/${perfil['id']}');
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Perfil "$nombre" desactivado')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	void _abrirDerechos(Map<String, dynamic> perfil) {
		context.push(
			'/perfiles/${perfil['id']}/derechos',
			extra: perfil['nombre'] as String?,
		);
	}

	@override
	Widget build(BuildContext context) {
		final puedeAgregar = _tieneDerecho('configuracion.perfiles.agregar');
		final puedeModificar = _tieneDerecho('configuracion.perfiles.modificar');
		final puedeBorrar = _tieneDerecho('configuracion.perfiles.borrar');
		final puedeDerechos = _tieneDerecho('configuracion.perfiles.definir_derechos');

		return Column(
			children: [
				_PageHeader(
					title: 'Perfiles',
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

							final perfiles = snapshot.data ?? [];
							return ListView.separated(
								padding: const EdgeInsets.all(20),
								itemCount: perfiles.length,
								separatorBuilder: (_, __) => const SizedBox(height: 8),
								itemBuilder: (context, index) {
									final item = perfiles[index] as Map<String, dynamic>;
									final count = item['_count'] as Map<String, dynamic>?;
									final activo = item['activo'] as bool? ?? false;

									return Material(
										color: Theme.of(context).colorScheme.surface,
										borderRadius: BorderRadius.circular(16),
										child: ListTile(
											contentPadding: const EdgeInsets.symmetric(
												horizontal: 16,
												vertical: 8,
											),
											onTap: puedeModificar ? () => _editar(item) : null,
											leading: const Icon(Icons.badge_outlined),
											title: Text(
												item['nombre'] as String,
												style: const TextStyle(fontWeight: FontWeight.w600),
											),
											subtitle: Text(
												item['descripcion'] as String? ??
														'${count?['usuarios'] ?? 0} usuarios · ${count?['derechos'] ?? 0} derechos',
											),
											trailing: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													if (puedeDerechos)
														IconButton(
															tooltip: 'Derechos',
															onPressed: () => _abrirDerechos(item),
															icon: const Icon(Icons.account_tree_outlined),
														),
													Chip(
														label: Text(activo ? 'Activo' : 'Inactivo'),
														backgroundColor: activo
																? AppColors.success.withValues(alpha: 0.15)
																: Colors.grey.withValues(alpha: 0.15),
													),
													if (puedeBorrar && activo)
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
							icon: const Icon(Icons.add_rounded, size: 18),
							label: const Text('Nuevo'),
						),
					if (onAdd != null) const SizedBox(width: 8),
					IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
				],
			),
		);
	}
}
