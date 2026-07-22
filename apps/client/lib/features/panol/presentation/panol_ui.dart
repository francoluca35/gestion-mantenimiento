import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tokens del dashboard Pañol adaptados a light / dark.
class PanolPalette {
	const PanolPalette({
		required this.canvas,
		required this.surface,
		required this.border,
		required this.ink,
		required this.muted,
		required this.softYellow,
		required this.softRed,
		required this.softGreen,
		required this.rowAlt,
		required this.chipBg,
		required this.isDark,
	});

	final Color canvas;
	final Color surface;
	final Color border;
	final Color ink;
	final Color muted;
	final Color softYellow;
	final Color softRed;
	final Color softGreen;
	final Color rowAlt;
	final Color chipBg;
	final bool isDark;

	static const rail = Color(0xFF12151A);
	static const railElevated = Color(0xFF1A1F27);
	static const railText = Color(0xFF9CA3AF);

	static PanolPalette of(BuildContext context) {
		final dark = Theme.of(context).brightness == Brightness.dark;
		if (dark) {
			return const PanolPalette(
				canvas: Color(0xFF000000),
				surface: Color(0xFF141216),
				border: Color(0xFF2E2838),
				ink: Color(0xFFF3F4F6),
				muted: Color(0xFF9A94A6),
				softYellow: Color(0xFF2A1838),
				softRed: Color(0xFF3A1814),
				softGreen: Color(0xFF143018),
				rowAlt: Color(0xFF100E14),
				chipBg: Color(0xFF1E1A24),
				isDark: true,
			);
		}
		return const PanolPalette(
			canvas: Color(0xFFF7F5FA),
			surface: Color(0xFFFFFFFF),
			border: Color(0xFFE4DCEF),
			ink: Color(0xFF111827),
			muted: Color(0xFF6B7280),
			softYellow: Color(0xFFF5E8FF),
			softRed: Color(0xFFFFE8E3),
			softGreen: Color(0xFFE6FBE6),
			rowAlt: Color(0xFFFAF8FC),
			chipBg: Color(0xFFF3EFF8),
			isDark: false,
		);
	}

	List<BoxShadow> get softShadow => [
				BoxShadow(
					color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
					blurRadius: 18,
					offset: const Offset(0, 6),
				),
			];
}

/// Alias de acceso rápido.
class PanolUi {
	const PanolUi._();

	static PanolPalette of(BuildContext context) => PanolPalette.of(context);

	static const Color rail = PanolPalette.rail;
	static const Color railElevated = PanolPalette.railElevated;
	static const Color railText = PanolPalette.railText;
}

class PanolPageFade extends StatelessWidget {
	const PanolPageFade({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) {
		return TweenAnimationBuilder<double>(
			tween: Tween(begin: 0, end: 1),
			duration: const Duration(milliseconds: 380),
			curve: Curves.easeOutCubic,
			builder: (context, t, child) => Opacity(
				opacity: t,
				child: Transform.translate(
					offset: Offset(0, 12 * (1 - t)),
					child: child,
				),
			),
			child: child,
		);
	}
}

class PanolKpi extends StatelessWidget {
	const PanolKpi({
		super.key,
		required this.label,
		required this.value,
		required this.icon,
		this.tone = PanolKpiTone.neutral,
		this.hint,
	});

	final String label;
	final num value;
	final IconData icon;
	final PanolKpiTone tone;
	final String? hint;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		final (bg, fg, iconBg) = switch (tone) {
			PanolKpiTone.warning => (
					ui.softYellow,
					ui.isDark ? AppColors.brandYellow : AppColors.ink,
					AppColors.brandYellow.withValues(alpha: 0.35),
				),
			PanolKpiTone.danger => (
					ui.softRed,
					AppColors.brandRed,
					AppColors.brandRed.withValues(alpha: 0.18),
				),
			PanolKpiTone.success => (
					ui.softGreen,
					AppColors.success,
					AppColors.success.withValues(alpha: 0.18),
				),
			PanolKpiTone.neutral => (
					ui.surface,
					ui.ink,
					ui.chipBg,
				),
		};

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: ui.border),
				boxShadow: ui.softShadow,
			),
			child: Row(
				children: [
					Container(
						width: 42,
						height: 42,
						decoration: BoxDecoration(
							color: iconBg,
							borderRadius: BorderRadius.circular(12),
						),
						child: Icon(icon, color: fg, size: 22),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									label,
									style: TextStyle(
										color: ui.muted,
										fontSize: 12,
										fontWeight: FontWeight.w600,
										letterSpacing: 0.2,
									),
								),
								const SizedBox(height: 2),
								TweenAnimationBuilder<double>(
									tween: Tween(begin: 0, end: value.toDouble()),
									duration: const Duration(milliseconds: 700),
									curve: Curves.easeOutCubic,
									builder: (context, v, _) => Text(
										v.round().toString(),
										style: TextStyle(
											color: fg,
											fontSize: 26,
											fontWeight: FontWeight.w800,
											height: 1.1,
											letterSpacing: -0.5,
										),
									),
								),
								if (hint != null) ...[
									const SizedBox(height: 2),
									Text(
										hint!,
										style: TextStyle(color: ui.muted, fontSize: 11),
									),
								],
							],
						),
					),
				],
			),
		);
	}
}

enum PanolKpiTone { neutral, warning, danger, success }

/// Resumen colapsable: por defecto cerrado para priorizar listados.
class PanolCollapsibleKpis extends StatefulWidget {
	const PanolCollapsibleKpis({
		super.key,
		required this.kpis,
		this.title = 'Resumen',
		this.initiallyExpanded = false,
	});

	final List<PanolKpi> kpis;
	final String title;
	final bool initiallyExpanded;

	@override
	State<PanolCollapsibleKpis> createState() => _PanolCollapsibleKpisState();
}

class _PanolCollapsibleKpisState extends State<PanolCollapsibleKpis>
		with SingleTickerProviderStateMixin {
	late bool _expanded = widget.initiallyExpanded;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Material(
					color: ui.surface,
					borderRadius: BorderRadius.circular(12),
					child: InkWell(
						onTap: () => setState(() => _expanded = !_expanded),
						borderRadius: BorderRadius.circular(12),
						child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: ui.border),
							),
							child: Row(
								children: [
									Icon(
										Icons.insights_outlined,
										size: 18,
										color: ui.muted,
									),
									const SizedBox(width: 8),
									Expanded(
										child: Text(
											widget.title,
											style: TextStyle(
												fontWeight: FontWeight.w700,
												fontSize: 13,
												color: ui.ink,
											),
										),
									),
									if (!_expanded)
										Flexible(
											child: SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												reverse: true,
												child: Row(
													children: [
														for (final kpi in widget.kpis) ...[
															const SizedBox(width: 6),
															_MiniKpiChip(kpi: kpi),
														],
													],
												),
											),
										),
									const SizedBox(width: 4),
									AnimatedRotation(
										turns: _expanded ? 0.5 : 0,
										duration: const Duration(milliseconds: 180),
										child: Icon(
											Icons.keyboard_arrow_down_rounded,
											color: ui.ink,
										),
									),
								],
							),
						),
					),
				),
				AnimatedCrossFade(
					firstChild: const SizedBox(width: double.infinity, height: 0),
					secondChild: Padding(
						padding: const EdgeInsets.only(top: 10),
						child: LayoutBuilder(
							builder: (context, c) {
								final cols = c.maxWidth > 900
										? 4
										: c.maxWidth > 560
												? 2
												: 1;
								return Wrap(
									spacing: 10,
									runSpacing: 10,
									children: [
										for (final kpi in widget.kpis)
											SizedBox(
												width: (c.maxWidth - (cols - 1) * 10) / cols,
												child: kpi,
											),
									],
								);
							},
						),
					),
					crossFadeState: _expanded
							? CrossFadeState.showSecond
							: CrossFadeState.showFirst,
					duration: const Duration(milliseconds: 220),
					sizeCurve: Curves.easeOutCubic,
				),
			],
		);
	}
}

class _MiniKpiChip extends StatelessWidget {
	const _MiniKpiChip({required this.kpi});

	final PanolKpi kpi;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		final (bg, fg) = switch (kpi.tone) {
			PanolKpiTone.danger => (ui.softRed, AppColors.brandRed),
			PanolKpiTone.success => (ui.softGreen, AppColors.success),
			PanolKpiTone.warning => (
					ui.softYellow,
					ui.isDark ? AppColors.brandPurple : AppColors.brandPurpleDark,
				),
			PanolKpiTone.neutral => (ui.chipBg, ui.muted),
		};
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				'${kpi.value.round()}',
				style: TextStyle(
					color: fg,
					fontWeight: FontWeight.w800,
					fontSize: 11,
				),
			),
		);
	}
}

class PanolSectionTitle extends StatelessWidget {
	const PanolSectionTitle({
		super.key,
		required this.title,
		this.subtitle,
		this.trailing,
	});

	final String title;
	final String? subtitle;
	final Widget? trailing;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		return Row(
			crossAxisAlignment: CrossAxisAlignment.end,
			children: [
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								title,
								style: TextStyle(
									fontSize: 22,
									fontWeight: FontWeight.w800,
									color: ui.ink,
									letterSpacing: -0.4,
								),
							),
							if (subtitle != null) ...[
								const SizedBox(height: 4),
								Text(
									subtitle!,
									style: TextStyle(
										color: ui.muted,
										fontSize: 13,
										height: 1.35,
									),
								),
							],
						],
					),
				),
				if (trailing != null) trailing!,
			],
		);
	}
}

class PanolSurface extends StatelessWidget {
	const PanolSurface({
		super.key,
		required this.child,
		this.padding,
		this.clip = false,
	});

	final Widget child;
	final EdgeInsetsGeometry? padding;
	final bool clip;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		return Container(
			clipBehavior: clip ? Clip.antiAlias : Clip.none,
			padding: padding,
			decoration: BoxDecoration(
				color: ui.surface,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: ui.border),
				boxShadow: ui.softShadow,
			),
			child: child,
		);
	}
}

class PanolToolbarButton extends StatefulWidget {
	const PanolToolbarButton({
		super.key,
		required this.label,
		required this.icon,
		this.onTap,
		this.variant = PanolToolbarVariant.primary,
	});

	final String label;
	final IconData icon;
	final VoidCallback? onTap;
	final PanolToolbarVariant variant;

	@override
	State<PanolToolbarButton> createState() => _PanolToolbarButtonState();
}

class _PanolToolbarButtonState extends State<PanolToolbarButton> {
	bool _pressed = false;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		final enabled = widget.onTap != null;
		final (bg, fg, border) = switch (widget.variant) {
			PanolToolbarVariant.primary => (
					AppColors.brandYellow,
					AppColors.ink,
					AppColors.brandYellow,
				),
			PanolToolbarVariant.secondary => (
					ui.surface,
					ui.ink,
					ui.border,
				),
			PanolToolbarVariant.danger => (
					ui.softRed,
					AppColors.brandRed,
					ui.isDark ? const Color(0xFF5A2A2E) : const Color(0xFFF5C2C5),
				),
		};

		return AnimatedScale(
			scale: _pressed ? 0.97 : 1,
			duration: const Duration(milliseconds: 120),
			child: Material(
				color: enabled ? bg : bg.withValues(alpha: 0.45),
				borderRadius: BorderRadius.circular(12),
				child: InkWell(
					onTap: widget.onTap,
					onHighlightChanged: (v) => setState(() => _pressed = v),
					borderRadius: BorderRadius.circular(12),
					child: Container(
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(12),
							border: Border.all(color: border),
						),
						child: Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								Icon(widget.icon, size: 18, color: fg),
								const SizedBox(width: 8),
								Text(
									widget.label,
									style: TextStyle(
										color: fg,
										fontWeight: FontWeight.w700,
										fontSize: 13,
										letterSpacing: 0.2,
									),
								),
							],
						),
					),
				),
			),
		);
	}
}

enum PanolToolbarVariant { primary, secondary, danger }

class PanolStatusPill extends StatelessWidget {
	const PanolStatusPill({
		super.key,
		required this.label,
		required this.tone,
	});

	final String label;
	final PanolKpiTone tone;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		final (bg, fg) = switch (tone) {
			PanolKpiTone.danger => (ui.softRed, AppColors.brandRed),
			PanolKpiTone.success => (ui.softGreen, AppColors.success),
			PanolKpiTone.warning => (
					ui.softYellow,
					ui.isDark ? AppColors.brandPurple : AppColors.brandPurpleDark,
				),
			PanolKpiTone.neutral => (ui.chipBg, ui.muted),
		};
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				label,
				style: TextStyle(
					color: fg,
					fontWeight: FontWeight.w700,
					fontSize: 11,
					letterSpacing: 0.3,
				),
			),
		);
	}
}

class PanolSearchField extends StatelessWidget {
	const PanolSearchField({
		super.key,
		required this.onChanged,
		this.hint = 'Buscar…',
	});

	final ValueChanged<String> onChanged;
	final String hint;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		return TextField(
			onChanged: onChanged,
			style: TextStyle(color: ui.ink, fontSize: 14),
			decoration: InputDecoration(
				hintText: hint,
				hintStyle: TextStyle(color: ui.muted),
				prefixIcon: Icon(Icons.search_rounded, color: ui.muted),
				filled: true,
				fillColor: ui.surface,
				contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide(color: ui.border),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: BorderSide(color: ui.border),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: const BorderSide(color: AppColors.brandYellow, width: 1.5),
				),
			),
		);
	}
}

class PanolEmptyState extends StatelessWidget {
	const PanolEmptyState({
		super.key,
		required this.icon,
		required this.title,
		this.subtitle,
	});

	final IconData icon;
	final String title;
	final String? subtitle;

	@override
	Widget build(BuildContext context) {
		final ui = PanolUi.of(context);
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(32),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Container(
							width: 64,
							height: 64,
							decoration: BoxDecoration(
								color: ui.chipBg,
								borderRadius: BorderRadius.circular(18),
							),
							child: Icon(icon, size: 28, color: ui.muted),
						),
						const SizedBox(height: 16),
						Text(
							title,
							textAlign: TextAlign.center,
							style: TextStyle(
								fontWeight: FontWeight.w700,
								fontSize: 16,
								color: ui.ink,
							),
						),
						if (subtitle != null) ...[
							const SizedBox(height: 6),
							Text(
								subtitle!,
								textAlign: TextAlign.center,
								style: TextStyle(color: ui.muted, height: 1.4),
							),
						],
					],
				),
			),
		);
	}
}

PanolKpiTone pedidoTone(String estado) {
	return switch (estado) {
		'en_proceso' => PanolKpiTone.warning,
		'completado' => PanolKpiTone.success,
		_ => PanolKpiTone.danger,
	};
}

String pedidoLabel(String estado) {
	return switch (estado) {
		'en_proceso' => 'En proceso',
		'completado' => 'Completado',
		_ => 'Pendiente',
	};
}
