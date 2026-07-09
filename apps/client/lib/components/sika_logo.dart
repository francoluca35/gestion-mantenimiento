import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Logo triangular Sika + tagline corporativa.
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
		final tagColor = taglineColor ?? AppColors.accent;

		if (compact) {
			return CustomPaint(
				size: Size(size, size * 0.9),
				painter: const _SikaTrianglePainter(),
			);
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			mainAxisSize: MainAxisSize.min,
			children: [
				CustomPaint(
					size: Size(size, size * 0.9),
					painter: const _SikaTrianglePainter(),
				),
				if (showTagline) ...[
					const SizedBox(height: 6),
					Text(
						'CONSTRUYENDO CONFIANZA',
						style: TextStyle(
							color: tagColor,
							fontSize: size * 0.22,
							fontWeight: FontWeight.w800,
							letterSpacing: 0.4,
							height: 1.1,
						),
					),
				],
			],
		);
	}
}

class _SikaTrianglePainter extends CustomPainter {
	const _SikaTrianglePainter();

	@override
	void paint(Canvas canvas, Size size) {
		final path = Path()
				..moveTo(size.width * 0.5, 0)
				..lineTo(size.width, size.height)
				..lineTo(0, size.height)
				..close();

		canvas.drawPath(path, Paint()..color = AppColors.accent);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
