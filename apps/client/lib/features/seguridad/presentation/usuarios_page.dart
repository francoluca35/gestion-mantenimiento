import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'usuario_form_sheet.dart';

class UsuariosPage extends ConsumerStatefulWidget {
	const UsuariosPage({super.key});

	@override
	ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
	late Future<List<dynamic>> _future;

	@override
	void initState() {
		super.initState();
		_future = _load();
	}

	Future<List<dynamic>> _load() {
		return ref.read(apiClientProvider).getList('usuarios');
	}

	void _refresh() => setState(() => _future = _load());

	bool get _puedeAgregar {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.tieneDerecho('configuracion.usuarios.agregar') ?? false;
	}

	bool get _puedeModificar {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.tieneDerecho('configuracion.usuarios.modificar') ?? false;
	}

	bool get _puedeBorrar {
		final user = ref.read(authControllerProvider).session?.usuario;
		return user?.tieneDerecho('configuracion.usuarios.borrar') ?? false;
	}

	Future<void> _crear() async {
		final ok = await showUsuarioForm(context, ref);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Usuario creado')),
			);
		}
	}

	Future<void> _editar(Map<String, dynamic> usuario) async {
		final ok = await showUsuarioForm(context, ref, usuario: usuario);
		if (ok == true) {
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Usuario actualizado')),
			);
		}
	}

	Future<void> _desactivar(Map<String, dynamic> usuario) async {
		final nombre = usuario['nombreUsuario'] as String? ?? '';
		final confirmado = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Desactivar usuario'),
				content: Text(
					'¿Desactivar a "$nombre"? No podrá iniciar sesión.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						style: FilledButton.styleFrom(
							backgroundColor: AppColors.danger,
						),
						onPressed: () => Navigator.pop(context, true),
						child: const Text('Desactivar'),
					),
				],
			),
		);

		if (confirmado != true) return;

		try {
			await ref.read(apiClientProvider).deleteJson('usuarios/${usuario['id']}');
			_refresh();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Usuario "$nombre" desactivado')),
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
		final session = ref.watch(authControllerProvider).session;
		final currentUserId = session?.usuario.id;

		return Column(
			children: [
				_PageHeader(
					title: 'Usuarios',
					onRefresh: _refresh,
					onAdd: _puedeAgregar ? _crear : null,
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

							final usuarios = snapshot.data ?? [];
							if (usuarios.isEmpty) {
								return const Center(child: Text('No hay usuarios'));
							}

							return ListView.separated(
								padding: const EdgeInsets.all(20),
								itemCount: usuarios.length,
								separatorBuilder: (_, __) => const SizedBox(height: 8),
								itemBuilder: (context, index) {
									final usuario = usuarios[index] as Map<String, dynamic>;
									final perfil = usuario['perfil'] as Map<String, dynamic>?;
									final sucursal = usuario['sucursal'] as Map<String, dynamic>?;
									final activo = usuario['activo'] as bool? ?? false;
									final esYo = usuario['id'] == currentUserId;

									return Material(
										color: Theme.of(context).colorScheme.surface,
										borderRadius: BorderRadius.circular(16),
										child: ListTile(
											contentPadding: const EdgeInsets.symmetric(
												horizontal: 16,
												vertical: 8,
											),
											onTap: _puedeModificar ? () => _editar(usuario) : null,
											leading: CircleAvatar(
												backgroundColor: Theme.of(context)
														.colorScheme
														.primary
														.withValues(alpha: 0.12),
												child: Text(
													(usuario['nombreUsuario'] as String)
															.substring(0, 1)
															.toUpperCase(),
												),
											),
											title: Text(
												usuario['nombreUsuario'] as String,
												style: const TextStyle(fontWeight: FontWeight.w600),
											),
											subtitle: Text(
												[
													perfil?['nombre'] ?? 'Sin perfil',
													sucursal?['nombre'] ?? 'Todas las sucursales',
													if (usuario['esAdministrador'] == true)
														'Admin',
												].join(' · '),
											),
											trailing: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Chip(
														label: Text(activo ? 'Activo' : 'Inactivo'),
														backgroundColor: activo
																? AppColors.success.withValues(alpha: 0.15)
																: Colors.grey.withValues(alpha: 0.15),
													),
													if (_puedeBorrar && activo && !esYo)
														IconButton(
															tooltip: 'Desactivar',
															onPressed: () => _desactivar(usuario),
															icon: const Icon(
																Icons.person_off_outlined,
																size: 20,
															),
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
							icon: const Icon(Icons.person_add_outlined, size: 18),
							label: const Text('Nuevo'),
						),
					if (onAdd != null) const SizedBox(width: 8),
					IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
				],
			),
		);
	}
}
