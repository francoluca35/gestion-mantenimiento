import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import 'panol_ui.dart';

/// Pantalla principal del rol Pañol: notificaciones + acceso a módulos.
class PanolHomePage extends ConsumerStatefulWidget {
	const PanolHomePage({super.key});

	@override
	ConsumerState<PanolHomePage> createState() => _PanolHomePageState();
}

class _PanolHomePageState extends ConsumerState<PanolHomePage> {
	static final _dateFmt = DateFormat('dd/MM HH:mm');

	List<Map<String, dynamic>> _pedidos = [];
	List<Map<String, dynamic>> _solicitudes = [];
	bool _loading = true;
	String? _error;

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
			final api = ref.read(apiClientProvider);
			final pedidos =
					(await api.getList('pedidos-stock')).cast<Map<String, dynamic>>();
			List<Map<String, dynamic>> solicitudes = [];
			try {
				solicitudes =
						(await api.getList('solicitudes-materiales?estado=pendiente'))
								.cast<Map<String, dynamic>>();
			} catch (_) {}
			if (!mounted) return;
			setState(() {
				_pedidos = pedidos;
				_solicitudes = solicitudes;
			});
		} catch (e) {
			if (mounted) setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	List<_PanolNotif> get _notificaciones {
		final items = <_PanolNotif>[];

		for (final sol in _solicitudes) {
			final mat = sol['material'] as Map<String, dynamic>? ?? {};
			final ot = sol['ot'] as Map<String, dynamic>? ?? {};
			final fecha = sol['fechaSolicitud'] != null
					? DateTime.tryParse(sol['fechaSolicitud'].toString())
					: null;
			items.add(
				_PanolNotif(
					id: 'sol-${sol['id']}',
					title: 'Solicitud OT #${ot['numero'] ?? '—'}',
					body: '${mat['nombre'] ?? 'Material'} · Cant. ${sol['cantidad']}',
					tone: PanolKpiTone.danger,
					icon: Icons.assignment_late_outlined,
					fecha: fecha,
					route: '/panol/pedidos',
				),
			);
		}

		for (final p in _pedidos.where((p) => p['estado'] != 'completado')) {
			final mat = p['material'] as Map<String, dynamic>? ?? {};
			final numero = p['numero'] as int? ?? 0;
			final estado = p['estado'] as String? ?? 'pendiente';
			final fecha = p['createdAt'] != null
					? DateTime.tryParse(p['createdAt'].toString())
					: null;
			items.add(
				_PanolNotif(
					id: 'pd-${p['id']}',
					title: 'Pedido PD-${numero.toString().padLeft(4, '0')}',
					body: '${mat['nombre'] ?? ''} · ${pedidoLabel(estado)}',
					tone: pedidoTone(estado),
					icon: Icons.local_shipping_outlined,
					fecha: fecha,
					route: '/panol/pedidos',
				),
			);
		}

		items.sort((a, b) {
			final da = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
			final db = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
			return db.compareTo(da);
		});
		return items;
	}

	@override
	Widget build(BuildContext context) {
		final notifs = _notificaciones;
		final user = ref.watch(authControllerProvider).session?.usuario;

		return ColoredBox(
			color: PanolUi.of(context).canvas,
			child: PanolPageFade(
				child: RefreshIndicator(
					onRefresh: _cargar,
					color: AppColors.brandYellow,
					child: ListView(
						padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
						children: [
							Text(
								'Hola, ${user?.nombreUsuario ?? 'pañol'}',
								style: TextStyle(
									fontSize: 24,
									fontWeight: FontWeight.w800,
									color: PanolUi.of(context).ink,
									letterSpacing: -0.4,
								),
							),
							SizedBox(height: 4),
							Text(
								'Centro de operación del pañol',
								style: TextStyle(color: PanolUi.of(context).muted, fontSize: 14),
							),
							const SizedBox(height: 20),
							_NotificationsBlock(
								loading: _loading,
								error: _error,
								items: notifs,
								dateFmt: _dateFmt,
								onOpen: (route) => context.go(route),
								onRetry: _cargar,
							),
							SizedBox(height: 28),
							Text(
								'Módulos',
								style: TextStyle(
									fontWeight: FontWeight.w800,
									fontSize: 16,
									color: PanolUi.of(context).ink,
								),
							),
							const SizedBox(height: 12),
							LayoutBuilder(
								builder: (context, c) {
									final wide = c.maxWidth >= 560;
									final tileW = wide
											? (c.maxWidth - 12) / 2
											: c.maxWidth;
									final modules = [
										_ModuleTile(
											title: 'Dashboard de pedidos',
											subtitle: 'Resumen y estado general',
											icon: Icons.dashboard_customize_outlined,
											accent: AppColors.brandYellow,
											route: '/panol/dashboard',
										),
										_ModuleTile(
											title: 'Pedidos',
											subtitle: 'Reposición y solicitudes OT',
											icon: Icons.receipt_long_rounded,
											accent: AppColors.brandRed,
											route: '/panol/pedidos',
											badge: notifs.isEmpty ? null : '${notifs.length}',
										),
										_ModuleTile(
											title: 'Stock',
											subtitle: 'Inventario y materiales',
											icon: Icons.inventory_2_rounded,
											accent: AppColors.success,
											route: '/panol/stock',
										),
										_ModuleTile(
											title: 'Seguimiento',
											subtitle: 'Movimientos del pañol',
											icon: Icons.timeline_rounded,
											accent: PanolUi.of(context).isDark
													? const Color(0xFFD1D5DB)
													: const Color(0xFF4B5563),
											route: '/panol/seguimiento',
										),
									];
									return Wrap(
										spacing: 12,
										runSpacing: 12,
										children: [
											for (final m in modules)
												SizedBox(width: tileW, child: m),
										],
									);
								},
							),
						],
					),
				),
			),
		);
	}
}

class _PanolNotif {
	const _PanolNotif({
		required this.id,
		required this.title,
		required this.body,
		required this.tone,
		required this.icon,
		required this.route,
		this.fecha,
	});

	final String id;
	final String title;
	final String body;
	final PanolKpiTone tone;
	final IconData icon;
	final String route;
	final DateTime? fecha;
}

class _NotificationsBlock extends StatelessWidget {
	const _NotificationsBlock({
		required this.loading,
		required this.error,
		required this.items,
		required this.dateFmt,
		required this.onOpen,
		required this.onRetry,
	});

	final bool loading;
	final String? error;
	final List<_PanolNotif> items;
	final DateFormat dateFmt;
	final ValueChanged<String> onOpen;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		return PanolSurface(
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Container(
								width: 36,
								height: 36,
								decoration: BoxDecoration(
									color: PanolUi.of(context).softYellow,
									borderRadius: BorderRadius.circular(10),
								),
								child: Icon(
									Icons.notifications_active_outlined,
									color: PanolUi.of(context).isDark
											? AppColors.brandYellow
											: const Color(0xFF9A6B00),
									size: 20,
								),
							),
							const SizedBox(width: 10),
							Expanded(
								child: Text(
									'Notificaciones de pedidos',
									style: TextStyle(
										fontWeight: FontWeight.w800,
										fontSize: 15,
										color: PanolUi.of(context).ink,
									),
								),
							),
							if (items.isNotEmpty)
								PanolStatusPill(
									label: '${items.length} activas',
									tone: PanolKpiTone.warning,
								),
						],
					),
					const SizedBox(height: 14),
					if (loading)
						const Padding(
							padding: EdgeInsets.symmetric(vertical: 24),
							child: Center(child: CircularProgressIndicator()),
						)
					else if (error != null)
						Column(
							children: [
								Text(error!, style: const TextStyle(color: AppColors.brandRed)),
								TextButton(onPressed: onRetry, child: const Text('Reintentar')),
							],
						)
					else if (items.isEmpty)
						Container(
							padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
							decoration: BoxDecoration(
								color: PanolUi.of(context).softGreen,
								borderRadius: BorderRadius.circular(12),
							),
							child: const Row(
								children: [
									Icon(Icons.check_circle_outline, color: AppColors.success),
									SizedBox(width: 10),
									Expanded(
										child: Text(
											'Sin pedidos pendientes por ahora.',
											style: TextStyle(
												color: AppColors.success,
												fontWeight: FontWeight.w600,
											),
										),
									),
								],
							),
						)
					else
						Column(
							children: [
								for (var i = 0; i < items.take(6).length; i++) ...[
									if (i > 0) const SizedBox(height: 8),
									_NotifTile(
										item: items[i],
										dateFmt: dateFmt,
										onTap: () => onOpen(items[i].route),
									),
								],
								if (items.length > 6) ...[
									const SizedBox(height: 8),
									TextButton(
										onPressed: () => onOpen('/panol/pedidos'),
										child: Text('Ver las ${items.length} notificaciones'),
									),
								],
							],
						),
				],
			),
		);
	}
}

class _NotifTile extends StatelessWidget {
	const _NotifTile({
		required this.item,
		required this.dateFmt,
		required this.onTap,
	});

	final _PanolNotif item;
	final DateFormat dateFmt;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		final (bg, fg) = switch (item.tone) {
			PanolKpiTone.danger => (ui.softRed, AppColors.brandRed),
			PanolKpiTone.warning => (
					ui.softYellow,
					ui.isDark ? AppColors.brandYellow : const Color(0xFF9A6B00),
				),
			PanolKpiTone.success => (ui.softGreen, AppColors.success),
			PanolKpiTone.neutral => (ui.chipBg, ui.muted),
		};

		return Material(
			color: ui.rowAlt,
			borderRadius: BorderRadius.circular(12),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(12),
				child: Container(
					padding: const EdgeInsets.all(12),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(12),
						border: Border.all(color: ui.border),
					),
					child: Row(
						children: [
							Container(
								width: 40,
								height: 40,
								decoration: BoxDecoration(
									color: bg,
									borderRadius: BorderRadius.circular(10),
								),
								child: Icon(item.icon, color: fg, size: 20),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											item.title,
											style: TextStyle(
												fontWeight: FontWeight.w800,
												fontSize: 13,
												color: ui.ink,
											),
										),
										const SizedBox(height: 2),
										Text(
											item.body,
											style: TextStyle(
												color: ui.muted,
												fontSize: 12,
											),
										),
									],
								),
							),
							if (item.fecha != null)
								Text(
									dateFmt.format(item.fecha!),
									style: TextStyle(
										color: ui.muted,
										fontSize: 11,
										fontWeight: FontWeight.w600,
									),
								),
							const SizedBox(width: 4),
							Icon(Icons.chevron_right, color: ui.muted),
						],
					),
				),
			),
		);
	}
}

class _ModuleTile extends StatefulWidget {
	const _ModuleTile({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.accent,
		required this.route,
		this.badge,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final Color accent;
	final String route;
	final String? badge;

	@override
	State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
	bool _pressed = false;

	@override
	Widget build(BuildContext context) {
		return AnimatedScale(
			scale: _pressed ? 0.98 : 1,
			duration: Duration(milliseconds: 120),
			child: Material(
				color: PanolUi.of(context).surface,
				borderRadius: BorderRadius.circular(18),
				child: InkWell(
					onTap: () => context.go(widget.route),
					onHighlightChanged: (v) => setState(() => _pressed = v),
					borderRadius: BorderRadius.circular(18),
					child: Container(
						constraints: BoxConstraints(minHeight: 120),
						padding: EdgeInsets.all(18),
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(18),
							border: Border.all(color: PanolUi.of(context).border),
							boxShadow: PanolUi.of(context).softShadow,
						),
						child: Row(
							children: [
								Container(
									width: 52,
									height: 52,
									decoration: BoxDecoration(
										color: widget.accent.withValues(alpha: 0.14),
										borderRadius: BorderRadius.circular(14),
									),
									child: Icon(widget.icon, color: widget.accent, size: 26),
								),
								const SizedBox(width: 14),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												widget.title,
												style: TextStyle(
													fontWeight: FontWeight.w800,
													fontSize: 16,
													color: PanolUi.of(context).ink,
												),
											),
											SizedBox(height: 4),
											Text(
												widget.subtitle,
												style: TextStyle(
													color: PanolUi.of(context).muted,
													fontSize: 12,
													height: 1.3,
												),
											),
										],
									),
								),
								if (widget.badge != null)
									Container(
										margin: const EdgeInsets.only(right: 6),
										padding: const EdgeInsets.symmetric(
											horizontal: 8,
											vertical: 4,
										),
										decoration: BoxDecoration(
											color: AppColors.brandRed,
											borderRadius: BorderRadius.circular(999),
										),
										child: Text(
											widget.badge!,
											style: const TextStyle(
												color: Colors.white,
												fontWeight: FontWeight.w800,
												fontSize: 11,
											),
										),
									),
								Icon(Icons.arrow_forward_rounded, color: PanolUi.of(context).muted),
							],
						),
					),
				),
			),
		);
	}
}