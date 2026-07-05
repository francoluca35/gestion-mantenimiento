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
		return Column(
			children: [
				_PageHeader(
					title: 'Plantas',
					onRefresh: () => setState(() => _future = _load()),
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
									return Material(
										color: Theme.of(context).colorScheme.surface,
										borderRadius: BorderRadius.circular(16),
										child: ListTile(
											contentPadding: const EdgeInsets.symmetric(
												horizontal: 16,
												vertical: 8,
											),
											leading: const Icon(Icons.apartment_rounded),
											title: Text(
												item['nombre'] as String,
												style: const TextStyle(fontWeight: FontWeight.w600),
											),
											subtitle: Text('Código: ${item['codigo']} · $count usuarios'),
											trailing: Chip(
												label: Text(
													(item['activa'] as bool? ?? false) ? 'Activa' : 'Inactiva',
												),
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
	const _PageHeader({required this.title, required this.onRefresh});

	final String title;
	final VoidCallback onRefresh;

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
					IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
				],
			),
		);
	}
}
