import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Sucursales'),
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

					final sucursales = snapshot.data ?? [];
					return ListView.separated(
						padding: const EdgeInsets.all(16),
						itemCount: sucursales.length,
						separatorBuilder: (_, __) => const SizedBox(height: 8),
						itemBuilder: (context, index) {
							final item = sucursales[index] as Map<String, dynamic>;
							final count = (item['_count'] as Map<String, dynamic>?)?['usuarios'] ?? 0;
							return Card(
								child: ListTile(
									leading: const Icon(Icons.apartment),
									title: Text(item['nombre'] as String),
									subtitle: Text('Código: ${item['codigo']} · $count usuarios'),
									trailing: Chip(
										label: Text((item['activa'] as bool? ?? false) ? 'Activa' : 'Inactiva'),
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
