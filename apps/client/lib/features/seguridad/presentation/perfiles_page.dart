import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Perfiles'),
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

					final perfiles = snapshot.data ?? [];
					return ListView.separated(
						padding: const EdgeInsets.all(16),
						itemCount: perfiles.length,
						separatorBuilder: (_, __) => const SizedBox(height: 8),
						itemBuilder: (context, index) {
							final item = perfiles[index] as Map<String, dynamic>;
							final count = item['_count'] as Map<String, dynamic>?;
							return Card(
								child: ListTile(
									leading: const Icon(Icons.badge_outlined),
									title: Text(item['nombre'] as String),
									subtitle: Text(
										item['descripcion'] as String? ??
												'${count?['usuarios'] ?? 0} usuarios · ${count?['derechos'] ?? 0} derechos',
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
