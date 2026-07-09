import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class ContadoresPage extends ConsumerStatefulWidget {
	const ContadoresPage({super.key});

	@override
	ConsumerState<ContadoresPage> createState() => _ContadoresPageState();
}

class _ContadoresPageState extends ConsumerState<ContadoresPage> {
	List<Map<String, dynamic>> _equipos = [];
	bool _loading = true;
	String? _error;
	String _search = '';

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
	}

	Future<void> _cargar() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final user = ref.read(authControllerProvider).session?.usuario;
			final query = user?.sucursalId != null ? '?sucursalId=${user!.sucursalId}' : '';
			final lista = (await ref.read(apiClientProvider).getList('equipos$query'))
					.cast<Map<String, dynamic>>();
			if (!mounted) return;
			setState(() => _equipos = lista);
		} catch (error) {
			if (mounted) setState(() => _error = error.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	List<Map<String, dynamic>> get _filtrados {
		if (_search.isEmpty) return _equipos;
		final q = _search.toLowerCase();
		return _equipos.where((e) {
			final codigo = (e['codigo'] as String? ?? '').toLowerCase();
			final nombre = (e['nombre'] as String? ?? '').toLowerCase();
			return codigo.contains(q) || nombre.contains(q);
		}).toList();
	}

	@override
	Widget build(BuildContext context) {
		if (_loading) {
			return const Center(child: CircularProgressIndicator());
		}

		if (_error != null) {
			return Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(_error!),
						const SizedBox(height: 12),
						FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
					],
				),
			);
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Container(
					padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surface,
						border: Border(
							bottom: BorderSide(
								color: Theme.of(context)
										.colorScheme
										.outlineVariant
										.withValues(alpha: 0.35),
							),
						),
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									const Icon(Icons.speed_rounded, color: AppColors.primary),
									const SizedBox(width: 12),
									Expanded(
										child: Text(
											'Contadores',
											style: Theme.of(context).textTheme.titleLarge?.copyWith(
														fontWeight: FontWeight.w700,
													),
										),
									),
									IconButton(
										onPressed: _cargar,
										icon: const Icon(Icons.refresh_rounded),
									),
								],
							),
							const SizedBox(height: 4),
							Text(
								'Lecturas y contadores de equipos de tu planta',
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
											color: Theme.of(context).colorScheme.onSurfaceVariant,
										),
							),
							const SizedBox(height: 12),
							TextField(
								decoration: InputDecoration(
									hintText: 'Buscar equipo…',
									prefixIcon: const Icon(Icons.search_rounded, size: 20),
									isDense: true,
									border: OutlineInputBorder(
										borderRadius: BorderRadius.circular(12),
									),
								),
								onChanged: (value) => setState(() => _search = value),
							),
						],
					),
				),
				Expanded(
					child: _filtrados.isEmpty
							? const Center(child: Text('No hay equipos'))
							: ListView.separated(
									padding: const EdgeInsets.all(20),
									itemCount: _filtrados.length,
									separatorBuilder: (_, __) => const SizedBox(height: 8),
									itemBuilder: (context, index) {
										final equipo = _filtrados[index];
										final ubicacion =
												equipo['ubicacion'] as Map<String, dynamic>?;
										return Material(
											color: Theme.of(context).colorScheme.surface,
											borderRadius: BorderRadius.circular(14),
											child: ListTile(
												contentPadding: const EdgeInsets.symmetric(
													horizontal: 16,
													vertical: 8,
												),
												leading: CircleAvatar(
													backgroundColor:
															AppColors.primary.withValues(alpha: 0.12),
													child: const Icon(
														Icons.speed_rounded,
														color: AppColors.primary,
														size: 20,
													),
												),
												title: Text(
													'${equipo['codigo']} — ${equipo['nombre']}',
													style: const TextStyle(fontWeight: FontWeight.w600),
												),
												subtitle: Text(ubicacion?['nombre'] as String? ?? ''),
												trailing: const Icon(Icons.chevron_right_rounded),
												onTap: () => context.go('/planta'),
											),
										);
									},
								),
				),
			],
		);
	}
}
