import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class ContadoresPage extends ConsumerStatefulWidget {
	const ContadoresPage({super.key});

	@override
	ConsumerState<ContadoresPage> createState() => _ContadoresPageState();
}

class _ContadoresPageState extends ConsumerState<ContadoresPage> {
	List<Map<String, dynamic>> _equipos = [];
	final Map<String, List<Map<String, dynamic>>> _lecturasPorEquipo = {};
	final Set<String> _loadingLecturas = {};
	String? _expandedEquipoId;
	bool _loading = true;
	String? _error;
	String _search = '';

	bool get _esAdmin =>
			ref.read(authControllerProvider).session?.usuario.esAdministrador == true;

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

	Future<void> _cargarLecturas(String equipoId) async {
		if (_lecturasPorEquipo.containsKey(equipoId) || _loadingLecturas.contains(equipoId)) {
			return;
		}
		setState(() => _loadingLecturas.add(equipoId));
		try {
			final data = await ref.read(apiClientProvider).getList('equipos/$equipoId/lecturas');
			if (!mounted) return;
			setState(() => _lecturasPorEquipo[equipoId] = data.cast<Map<String, dynamic>>());
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		} finally {
			if (mounted) setState(() => _loadingLecturas.remove(equipoId));
		}
	}

	Future<void> _reiniciarContador(String equipoId, String tipo) async {
		if (_esAdmin) {
			final claveOk = await _confirmarClaveAdmin();
			if (claveOk != true || !mounted) return;
		}

		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Reiniciar contador'),
				content: Text(
					'¿Registrar reinicio del contador "$tipo" en 0? '
					'Solo administradores pueden hacerlo.',
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reiniciar')),
				],
			),
		);
		if (ok != true) return;

		try {
			await ref.read(apiClientProvider).postJson('equipos/$equipoId/lecturas/reiniciar', {
				'tipo': tipo,
				'valor': 0,
			});
			if (!mounted) return;
			_lecturasPorEquipo.remove(equipoId);
			await _cargarLecturas(equipoId);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Contador reiniciado')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
		}
	}

	Future<bool?> _confirmarClaveAdmin() async {
		final user = ref.read(authControllerProvider).session?.usuario;
		if (user == null) return false;

		final claveCtrl = TextEditingController();
		final result = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Confirmar clave de administrador'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Text(
							'Ingresá tu contraseña para reiniciar el contador.',
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
								fontSize: 13,
							),
						),
						const SizedBox(height: 12),
						TextField(
							controller: claveCtrl,
							autofocus: true,
							obscureText: true,
							decoration: const InputDecoration(
								labelText: 'Contraseña',
								border: OutlineInputBorder(),
							),
							onSubmitted: (_) => Navigator.pop(ctx, true),
						),
					],
				),
				actions: [
					TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
					FilledButton(
						onPressed: () => Navigator.pop(ctx, true),
						child: const Text('Confirmar'),
					),
				],
			),
		);
		final clave = claveCtrl.text;
		claveCtrl.dispose();
		if (result != true || !mounted) return false;

		try {
			await ref.read(apiClientProvider).postJson('auth/login', {
				'nombreUsuario': user.nombreUsuario,
				'clave': clave,
			});
			return true;
		} catch (_) {
			if (!mounted) return false;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Clave incorrecta')),
			);
			return false;
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
								'Lecturas por equipo. Expandí para ver el gráfico y reiniciar (admin).',
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
										final id = equipo['id'] as String;
										final expanded = _expandedEquipoId == id;
										final ubicacion =
												equipo['ubicacion'] as Map<String, dynamic>?;
										final lecturas = _lecturasPorEquipo[id] ?? [];
										final loadingLecturas = _loadingLecturas.contains(id);

										return Material(
											color: Theme.of(context).colorScheme.surface,
											borderRadius: BorderRadius.circular(14),
											child: Column(
												children: [
													ListTile(
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
														trailing: Icon(
															expanded
																	? Icons.expand_less_rounded
																	: Icons.expand_more_rounded,
														),
														onTap: () async {
															setState(() {
																_expandedEquipoId = expanded ? null : id;
															});
															if (!expanded) await _cargarLecturas(id);
														},
													),
													if (expanded) ...[
														const Divider(height: 1),
														Padding(
															padding: const EdgeInsets.all(16),
															child: loadingLecturas
																	? const Center(
																			child: CircularProgressIndicator(
																				strokeWidth: 2,
																			),
																		)
																	: lecturas.isEmpty
																			? const Text('Sin lecturas registradas')
																			: _LecturasChart(lecturas: lecturas),
														),
														if (expanded && lecturas.isNotEmpty && _esAdmin)
															Padding(
																padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
																child: Align(
																	alignment: Alignment.centerRight,
																	child: TextButton.icon(
																		onPressed: () => _reiniciarContador(
																			id,
																			lecturas.first['tipo'] as String? ?? 'horas',
																		),
																		icon: const Icon(Icons.restart_alt_rounded),
																		label: const Text('Reiniciar contador'),
																	),
																),
															),
													],
												],
											),
										);
									},
								),
				),
			],
		);
	}
}

class _LecturasChart extends StatelessWidget {
	const _LecturasChart({required this.lecturas});

	final List<Map<String, dynamic>> lecturas;

	double _valor(dynamic raw) {
		if (raw is num) return raw.toDouble();
		return double.tryParse(raw?.toString() ?? '') ?? 0;
	}

	@override
	Widget build(BuildContext context) {
		final items = lecturas.take(12).toList().reversed.toList();
		final max = items.map(_valor).fold<double>(0, (a, b) => a > b ? a : b);
		final scale = max > 0 ? max : 1;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				SizedBox(
					height: 80,
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: items.map((l) {
							final v = _valor(l['valor']);
							final h = (v / scale) * 64;
							return Expanded(
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 2),
									child: Container(
										height: h.clamp(4, 64),
										decoration: BoxDecoration(
											color: AppColors.primary.withValues(alpha: 0.85),
											borderRadius: BorderRadius.circular(4),
										),
									),
								),
							);
						}).toList(),
					),
				),
				const SizedBox(height: 12),
				...lecturas.take(5).map(
					(l) => ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						title: Text('${l['tipo']}: ${l['valor']}'),
						subtitle: Text('${l['fecha'] ?? ''}'),
					),
				),
			],
		);
	}
}
