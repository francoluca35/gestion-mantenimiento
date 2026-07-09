import 'package:flutter/material.dart';

/// Borde del panel colapsable respecto al contenido central.
enum PanelCollapseEdge {
	/// Panel a la izquierda — flecha en el borde derecho del panel.
	start,

	/// Panel a la derecha — flecha en el borde izquierdo del panel.
	end,
}

/// Rail vertical con flecha para expandir / contraer un panel lateral.
class PanelCollapseHandle extends StatelessWidget {
	const PanelCollapseHandle({
		super.key,
		required this.collapsed,
		required this.onToggle,
		required this.edge,
		this.topOffset = 72,
		this.expandTooltip = 'Expandir panel',
		this.collapseTooltip = 'Contraer panel',
	});

	final bool collapsed;
	final VoidCallback onToggle;
	final PanelCollapseEdge edge;
	final double topOffset;
	final String expandTooltip;
	final String collapseTooltip;

	IconData get _icon {
		return switch (edge) {
			PanelCollapseEdge.start =>
				collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
			PanelCollapseEdge.end =>
				collapsed ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
		};
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return SizedBox(
			width: 28,
			child: Material(
				color: scheme.surface,
				child: Column(
					children: [
						SizedBox(height: topOffset),
						IconButton(
							tooltip: collapsed ? expandTooltip : collapseTooltip,
							onPressed: onToggle,
							icon: Icon(_icon, size: 20),
							visualDensity: VisualDensity.compact,
							style: IconButton.styleFrom(
								backgroundColor: scheme.surfaceContainerHighest
										.withValues(alpha: 0.5),
							),
						),
						Expanded(
							child: VerticalDivider(
								width: 1,
								color: scheme.outlineVariant.withValues(alpha: 0.35),
							),
						),
					],
				),
			),
		);
	}
}

/// Envuelve un panel lateral con ancho animado.
class CollapsiblePanel extends StatelessWidget {
	const CollapsiblePanel({
		super.key,
		required this.collapsed,
		required this.expandedWidth,
		required this.child,
		this.collapsedWidth = 56,
		this.collapsedChild,
	});

	final bool collapsed;
	final double expandedWidth;
	final double collapsedWidth;
	final Widget child;
	final Widget? collapsedChild;

	@override
	Widget build(BuildContext context) {
		return AnimatedContainer(
			duration: const Duration(milliseconds: 240),
			curve: Curves.easeInOutCubic,
			width: collapsed ? collapsedWidth : expandedWidth,
			child: AnimatedSwitcher(
				duration: const Duration(milliseconds: 160),
				switchInCurve: Curves.easeOutCubic,
				switchOutCurve: Curves.easeInCubic,
				transitionBuilder: (child, animation) => FadeTransition(
					opacity: animation,
					child: child,
				),
				child: collapsed
						? KeyedSubtree(
							key: const ValueKey('collapsed'),
							child: collapsedChild ?? const SizedBox.shrink(),
						)
						: KeyedSubtree(
							key: const ValueKey('expanded'),
							child: child,
						),
			),
		);
	}
}
