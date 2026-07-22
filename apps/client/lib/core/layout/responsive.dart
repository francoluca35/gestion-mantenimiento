import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Dos campos en fila en desktop; apilados en mobile. No cambia PC (≥ tablet).
class ResponsivePair extends StatelessWidget {
	const ResponsivePair({
		super.key,
		required this.first,
		required this.second,
		this.spacing = 12,
		this.breakpoint = Breakpoints.tablet,
	});

	final Widget first;
	final Widget second;
	final double spacing;
	final double breakpoint;

	@override
	Widget build(BuildContext context) {
		final compact = MediaQuery.sizeOf(context).width < breakpoint;
		if (compact) {
			return Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					first,
					SizedBox(height: spacing),
					second,
				],
			);
		}
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Expanded(child: first),
				SizedBox(width: spacing),
				Expanded(child: second),
			],
		);
	}
}

/// Padding reducido solo en mobile.
EdgeInsets responsivePagePadding(BuildContext context, {double desktop = 24, double mobile = 14}) {
	final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
	final p = compact ? mobile : desktop;
	return EdgeInsets.all(p);
}

bool isCompactLayout(BuildContext context) =>
		MediaQuery.sizeOf(context).width < Breakpoints.tablet;
