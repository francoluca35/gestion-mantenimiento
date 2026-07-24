import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class IndicadoresPage extends ConsumerStatefulWidget {
	const IndicadoresPage({super.key});

	@override
	ConsumerState<IndicadoresPage> createState() => _IndicadoresPageState();
}

class _IndicadoresPageState extends ConsumerState<IndicadoresPage> {
	Map<String, dynamic>? _data;
	String? _error;
	bool _loading = true;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _load());
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final data =
					await ref.read(apiClientProvider).getJson('indicadores/dashboard');
			if (!mounted) return;
			setState(() {
				_data = data;
				_loading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_error = e.toString();
				_loading = false;
			});
		}
	}

	int _n(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final periodos = (_data?['periodos'] as Map?)?.cast<String, dynamic>();
		final estado = (_data?['estado'] as Map?)?.cast<String, dynamic>();
		final bandejas = (_data?['bandejas'] as Map?)?.cast<String, dynamic>();
		final porTecnico =
				(_data?['porTecnico'] as List?)?.cast<dynamic>() ?? const [];
		final cumplimiento = _n(_data?['cumplimientoMes']);

		return RefreshIndicator(
			onRefresh: _load,
			child: ListView(
				physics: const AlwaysScrollableScrollPhysics(),
				padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
				children: [
					Row(
						children: [
							Expanded(
								child: Text(
									'Indicadores',
									style: Theme.of(context).textTheme.headlineSmall?.copyWith(
												fontWeight: FontWeight.w800,
											),
								),
							),
							IconButton(
								onPressed: _loading ? null : _load,
								icon: const Icon(Icons.refresh_rounded),
							),
						],
					),
					const SizedBox(height: 4),
					Text(
						'Control operativo de la sucursal',
						style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
					),
					const SizedBox(height: 16),
					if (_loading)
						const Padding(
							padding: EdgeInsets.only(top: 48),
							child: Center(child: CircularProgressIndicator()),
						)
					else if (_error != null)
						Text(_error!, style: TextStyle(color: scheme.error))
					else ...[
						_Panel(
							title: 'OT PROGRAMADAS',
							child: Row(
								children: [
									_Period(label: 'Semana', value: '${_n(periodos?['semana'])}'),
									_Period(label: 'Mes', value: '${_n(periodos?['mes'])}', big: true),
									_Period(label: 'Año', value: '${_n(periodos?['anio'])}'),
								],
							),
						),
						const SizedBox(height: 12),
						_Panel(
							title: 'ESTADO ACTUAL',
							child: Wrap(
								spacing: 16,
								runSpacing: 10,
								children: [
									_Metric('Pendientes', _n(estado?['pendientes']), onTap: () => context.go('/ot')),
									_Metric('En curso', _n(estado?['enEjecucion']), onTap: () => context.go('/ot')),
									_Metric('Pañol', _n(estado?['pendientePanol']), onTap: () => context.go('/solicitudes-materiales')),
									_Metric('Atrasadas', _n(estado?['atrasadas']), onTap: () => context.go('/ot')),
									_Metric('Cumpl. mes', cumplimiento, suffix: '%', onTap: () => context.go('/ot/graficos')),
								],
							),
						),
						const SizedBox(height: 12),
						_Panel(
							title: 'BANDEJAS',
							child: Column(
								children: [
									_InboxRow(
										label: 'Solicitudes de trabajo',
										value: _n(bandejas?['solicitudesTrabajo']),
										onTap: () => context.go('/solicitudes'),
									),
									Divider(height: 1, color: isDark ? AppColors.cardBorder : const Color(0xFFE8ECF0)),
									_InboxRow(
										label: 'Pedidos materiales',
										value: _n(bandejas?['pedidosMateriales']),
										onTap: () => context.go('/solicitudes-materiales'),
									),
									Divider(height: 1, color: isDark ? AppColors.cardBorder : const Color(0xFFE8ECF0)),
									_InboxRow(
										label: 'OC por autorizar',
										value: _n(bandejas?['ocPendientesAutorizacion']),
										onTap: () => context.go('/compras'),
									),
								],
							),
						),
						const SizedBox(height: 12),
						_Panel(
							title: 'CARGA POR TÉCNICO',
							child: porTecnico.isEmpty
									? Text(
											'Sin OT abiertas asignadas',
											style: TextStyle(
												color: scheme.onSurface.withValues(alpha: 0.5),
											),
										)
									: Column(
											children: [
												for (final raw in porTecnico)
													Builder(
														builder: (_) {
															final row = (raw as Map).cast<String, dynamic>();
															return Padding(
																padding: const EdgeInsets.symmetric(vertical: 6),
																child: Row(
																	children: [
																		Expanded(
																			child: Text(
																				'${row['nombre'] ?? '—'}',
																				style: const TextStyle(fontWeight: FontWeight.w600),
																			),
																		),
																		Text(
																			'${_n(row['abiertas'])} abiertas',
																			style: TextStyle(
																				fontWeight: FontWeight.w800,
																				color: AppColors.accent,
																			),
																		),
																	],
																),
															);
														},
													),
											],
										),
						),
					],
				],
			),
		);
	}
}

class _Panel extends StatelessWidget {
	const _Panel({required this.title, required this.child});

	final String title;
	final Widget child;

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final scheme = Theme.of(context).colorScheme;
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
			decoration: BoxDecoration(
				color: scheme.surface,
				borderRadius: BorderRadius.circular(12),
				border: Border.all(
					color: isDark ? AppColors.cardBorder : const Color(0xFFE2E6EC),
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						title,
						style: TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w800,
							letterSpacing: 0.8,
							color: scheme.onSurface.withValues(alpha: 0.45),
						),
					),
					const SizedBox(height: 10),
					child,
				],
			),
		);
	}
}

class _Period extends StatelessWidget {
	const _Period({required this.label, required this.value, this.big = false});

	final String label;
	final String value;
	final bool big;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return Expanded(
			child: Column(
				children: [
					Text(
						label.toUpperCase(),
						style: TextStyle(
							fontSize: 11,
							fontWeight: FontWeight.w700,
							color: scheme.onSurface.withValues(alpha: 0.45),
						),
					),
					const SizedBox(height: 4),
					Text(
						value,
						style: TextStyle(
							fontSize: big ? 28 : 24,
							fontWeight: FontWeight.w800,
							letterSpacing: -0.6,
						),
					),
				],
			),
		);
	}
}

class _Metric extends StatelessWidget {
	const _Metric(this.label, this.value, {this.suffix = '', this.onTap});

	final String label;
	final int value;
	final String suffix;
	final VoidCallback? onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(6),
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
				child: RichText(
					text: TextSpan(
						children: [
							TextSpan(
								text: '$label  ',
								style: TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w600,
									color: scheme.onSurface.withValues(alpha: 0.5),
								),
							),
							TextSpan(
								text: '$value$suffix',
								style: TextStyle(
									fontSize: 13,
									fontWeight: FontWeight.w800,
									color: scheme.onSurface,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _InboxRow extends StatelessWidget {
	const _InboxRow({
		required this.label,
		required this.value,
		required this.onTap,
	});

	final String label;
	final int value;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return ListTile(
			contentPadding: EdgeInsets.zero,
			dense: true,
			title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
			trailing: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
						decoration: BoxDecoration(
							color: AppColors.accent.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(999),
						),
						child: Text(
							'$value',
							style: const TextStyle(
								fontWeight: FontWeight.w800,
								color: AppColors.accent,
							),
						),
					),
					const Icon(Icons.chevron_right_rounded),
				],
			),
			onTap: onTap,
		);
	}
}
