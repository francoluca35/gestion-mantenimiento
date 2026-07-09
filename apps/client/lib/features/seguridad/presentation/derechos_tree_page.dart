import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/sika_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class DerechosTreePage extends ConsumerStatefulWidget {
	const DerechosTreePage({super.key});

	@override
	ConsumerState<DerechosTreePage> createState() => _DerechosTreePageState();
}

class _DerechosTreePageState extends ConsumerState<DerechosTreePage> {
	late Future<List<dynamic>> _future;

	@override
	void initState() {
		super.initState();
		_future = ref.read(apiClientProvider).getList('derechos/tree');
	}

	Widget _buildNode(Map<String, dynamic> node, int depth) {
		final children = node['children'] as List<dynamic>? ?? [];
		return Padding(
			padding: EdgeInsets.only(left: depth * 16.0, bottom: 6),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Icon(
								children.isEmpty
										? Icons.insert_drive_file_outlined
										: Icons.folder_outlined,
								size: 18,
								color: AppColors.mutedText,
							),
							const SizedBox(width: 8),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											node['nombre'] as String? ?? '',
											style: const TextStyle(fontWeight: FontWeight.w600),
										),
										Text(
											node['codigo'] as String? ?? '',
											style: const TextStyle(
												fontSize: 12,
												color: AppColors.mutedText,
											),
										),
									],
								),
							),
						],
					),
					...children.map(
						(c) => _buildNode(c as Map<String, dynamic>, depth + 1),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				const SikaPageHeader(
					title: 'Árbol de derechos',
					subtitle: 'Catálogo global del sistema (solo lectura)',
					icon: Icons.account_tree_outlined,
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
							final roots = snapshot.data ?? [];
							return ListView(
								padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
								children: roots
										.map((n) => _buildNode(n as Map<String, dynamic>, 0))
										.toList(),
							);
						},
					),
				),
			],
		);
	}
}
