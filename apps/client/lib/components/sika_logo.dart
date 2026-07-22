import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Logo GESTION (imagen de marca) + tagline tricolor opcional.
class SikaLogo extends StatelessWidget {
	const SikaLogo({
		super.key,
		this.size = 40,
		this.showTagline = false,
		this.taglineColor,
		this.compact = false,
	});

	final double size;
	final bool showTagline;
	final Color? taglineColor;
	final bool compact;

	@override
	Widget build(BuildContext context) {
		final onSurface = Theme.of(context).colorScheme.onSurface;
		final sep = onSurface.withValues(alpha: 0.45);

		final mark = Image.asset(
			'assets/logo.png',
			width: size,
			height: size,
			fit: BoxFit.contain,
			filterQuality: FilterQuality.medium,
		);

		if (compact) return mark;

		final tagline = showTagline
				? (taglineColor != null
						? Text(
								'GESTIÓN INTELIGENTE',
								style: TextStyle(
									color: taglineColor,
									fontSize: size * 0.18,
									fontWeight: FontWeight.w800,
									letterSpacing: 0.6,
									height: 1.2,
								),
							)
						: Text.rich(
								TextSpan(
									style: TextStyle(
										fontSize: size * 0.18,
										fontWeight: FontWeight.w800,
										letterSpacing: 0.6,
										height: 1.2,
									),
									children: [
										const TextSpan(
											text: 'MANTENIMIENTO',
											style: TextStyle(color: AppColors.brandPurple),
										),
										TextSpan(
											text: ' | ',
											style: TextStyle(color: sep),
										),
										const TextSpan(
											text: 'STOCK',
											style: TextStyle(color: AppColors.brandGreen),
										),
										TextSpan(
											text: ' | ',
											style: TextStyle(color: sep),
										),
										const TextSpan(
											text: 'EFICIENCIA',
											style: TextStyle(color: AppColors.brandOrange),
										),
									],
								),
							))
				: null;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			mainAxisSize: MainAxisSize.min,
			children: [
				mark,
				if (tagline != null) ...[
					const SizedBox(height: 8),
					tagline,
				],
			],
		);
	}
}
