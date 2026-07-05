import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Usuarios'),
				actions: [
					IconButton(
						onPressed: () => setState(() => _future = _load()),
						icon: const Icon(Icons.refresh),
					),
				],
			),
			body: FutureBuilder<List<dynamic>>(
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
						padding: const EdgeInsets.all(16),
						itemCount: usuarios.length,
						separatorBuilder: (_, __) => const SizedBox(height: 8),
						itemBuilder: (context, index) {
							final usuario = usuarios[index] as Map<String, dynamic>;
							final perfil = usuario['perfil'] as Map<String, dynamic>?;
							final sucursal = usuario['sucursal'] as Map<String, dynamic>?;
							final activo = usuario['activo'] as bool? ?? false;

							return Card(
								child: ListTile(
									leading: CircleAvatar(
										child: Text(
											(usuario['nombreUsuario'] as String).substring(0, 1).toUpperCase(),
										),
									),
									title: Text(usuario['nombreUsuario'] as String),
									subtitle: Text(
										[
											perfil?['nombre'] ?? 'Sin perfil',
											sucursal?['nombre'] ?? 'Todas las sucursales',
										].join(' · '),
									),
									trailing: Chip(
										label: Text(activo ? 'Activo' : 'Inactivo'),
										backgroundColor: activo
												? Colors.green.withValues(alpha: 0.15)
												: Colors.grey.withValues(alpha: 0.15),
									),
								),
							);
						},
					);
				},
			),
		);
	}
}
