import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Tokens y widgets compartidos — paleta GESTION (claro/oscuro).
abstract final class SikaUi {
	static const double radiusSm = 12;
	static const double radiusMd = 16;
	static const double radiusLg = 20;

	static BoxDecoration cardDecoration({
		Color? color,
		bool selected = false,
		Color? accent,
		Brightness brightness = Brightness.dark,
	}) {
		final isDark = brightness == Brightness.dark;
		final surface = isDark ? AppColors.cardDark : AppColors.surfaceLight;
		final border = isDark ? AppColors.cardBorder : const Color(0xFFE4DCEF);

		return BoxDecoration(
			color: color ?? surface,
			borderRadius: BorderRadius.circular(radiusMd),
			border: Border.all(
				color: selected
						? (accent ?? AppColors.brandPurple).withValues(alpha: 0.55)
						: border,
				width: selected ? 1.5 : 1,
			),
		);
	}

	static InputDecoration searchDecoration({
		required BuildContext context,
		required String hint,
		Widget? suffix,
	}) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = scheme.brightness == Brightness.dark;
		final muted = isDark ? AppColors.mutedText : AppColors.secondary;

		return InputDecoration(
			hintText: hint,
			hintStyle: TextStyle(color: muted.withValues(alpha: 0.8)),
			prefixIcon: Icon(Icons.search_rounded, size: 20, color: muted),
			suffixIcon: suffix,
			isDense: true,
			filled: true,
			fillColor: isDark ? AppColors.cardElevated : AppColors.white,
			border: OutlineInputBorder(
				borderRadius: BorderRadius.circular(radiusSm),
				borderSide: BorderSide(color: scheme.outline),
			),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(radiusSm),
				borderSide: BorderSide(color: scheme.outline),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(radiusSm),
				borderSide: BorderSide(color: scheme.primary, width: 1.5),
			),
			contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
		);
	}
}

class SikaPageHeader extends StatelessWidget {
	const SikaPageHeader({
		super.key,
		required this.title,
		this.subtitle,
		this.icon,
		this.trailing,
		this.badge,
	});

	final String title;
	final String? subtitle;
	final IconData? icon;
	final Widget? trailing;
	final String? badge;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					if (icon != null) ...[
						Icon(icon, color: AppColors.accent, size: 26),
						const SizedBox(width: 10),
					],
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									title,
									style: Theme.of(context).textTheme.titleLarge?.copyWith(
												fontWeight: FontWeight.w700,
											),
								),
								if (subtitle != null) ...[
									const SizedBox(height: 4),
									Text(
										subtitle!,
										style: TextStyle(
											color: AppColors.mutedText,
											fontSize: 13,
										),
									),
								],
								if (badge != null) ...[
									const SizedBox(height: 8),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
										decoration: BoxDecoration(
											color: AppColors.accent.withValues(alpha: 0.12),
											borderRadius: BorderRadius.circular(999),
											border: Border.all(
												color: AppColors.accent.withValues(alpha: 0.3),
											),
										),
										child: Text(
											badge!,
											style: const TextStyle(
												color: AppColors.accent,
												fontWeight: FontWeight.w600,
												fontSize: 12,
											),
										),
									),
								],
							],
						),
					),
					if (trailing != null) trailing!,
				],
			),
		);
	}
}

class SikaCard extends StatelessWidget {
	const SikaCard({
		super.key,
		required this.child,
		this.onTap,
		this.padding = const EdgeInsets.all(20),
		this.selected = false,
		this.accent,
	});

	final Widget child;
	final VoidCallback? onTap;
	final EdgeInsets padding;
	final bool selected;
	final Color? accent;

	@override
	Widget build(BuildContext context) {
		final content = Container(
			padding: padding,
			decoration: SikaUi.cardDecoration(
				selected: selected,
				accent: accent,
				brightness: Theme.of(context).brightness,
			),
			child: child,
		);

		if (onTap == null) return content;

		return Material(
			color: Colors.transparent,
			child: InkWell(
				borderRadius: BorderRadius.circular(SikaUi.radiusMd),
				onTap: onTap,
				child: content,
			),
		);
	}
}

class SikaStatCard extends StatelessWidget {
	const SikaStatCard({
		super.key,
		required this.label,
		required this.value,
		required this.icon,
		required this.color,
	});

	final String label;
	final String value;
	final IconData icon;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: SikaUi.cardDecoration(
				brightness: Theme.of(context).brightness,
			),
			child: Row(
				children: [
					Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: color.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(12),
						),
						child: Icon(icon, color: color, size: 20),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									label,
									style: TextStyle(
										color: AppColors.mutedText,
										fontSize: 12,
									),
								),
								Text(
									value,
									style: TextStyle(
										color: color,
										fontWeight: FontWeight.w800,
										fontSize: 22,
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class SikaEmptyState extends StatelessWidget {
	const SikaEmptyState({
		super.key,
		required this.message,
		this.icon = Icons.inbox_outlined,
		this.compact = false,
	});

	final String message;
	final IconData icon;
	final bool compact;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final isDark = scheme.brightness == Brightness.dark;

		return Container(
			margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 6),
			padding: EdgeInsets.all(compact ? 16 : 24),
			decoration: BoxDecoration(
				color: (isDark ? AppColors.cardDark : AppColors.surfaceMuted)
						.withValues(alpha: isDark ? 0.5 : 1),
				borderRadius: BorderRadius.circular(SikaUi.radiusMd),
				border: Border.all(
					color: scheme.outline.withValues(alpha: 0.6),
					style: BorderStyle.solid,
				),
			),
			child: Row(
				children: [
					Icon(icon, color: AppColors.mutedText.withValues(alpha: 0.5), size: compact ? 20 : 28),
					const SizedBox(width: 12),
					Expanded(
						child: Text(
							message,
							style: TextStyle(
								color: AppColors.mutedText,
								fontSize: compact ? 12 : 13,
							),
						),
					),
				],
			),
		);
	}
}

class SikaBadge extends StatelessWidget {
	const SikaBadge({
		super.key,
		required this.label,
		this.color = AppColors.mutedText,
	});

	final String label;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
				border: Border.all(color: color.withValues(alpha: 0.35)),
			),
			child: Text(
				label,
				style: TextStyle(
					color: color,
					fontSize: 11,
					fontWeight: FontWeight.w700,
				),
			),
		);
	}
}
