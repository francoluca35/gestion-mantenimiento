import 'package:flutter/material.dart';

import 'breakpoints.dart';

class AdaptiveScaffold extends StatelessWidget {
	const AdaptiveScaffold({
		super.key,
		required this.title,
		required this.body,
		this.selectedIndex = 0,
		this.onDestinationSelected,
		this.destinations = const [],
		this.floatingActionButton,
		this.detailPanel,
	});

	final String title;
	final Widget body;
	final int selectedIndex;
	final ValueChanged<int>? onDestinationSelected;
	final List<NavigationDestination> destinations;
	final Widget? floatingActionButton;
	final Widget? detailPanel;

	@override
	Widget build(BuildContext context) {
		final width = MediaQuery.sizeOf(context).width;
		final isDesktop = Breakpoints.isDesktop(width);

		if (isDesktop) {
			return Scaffold(
				body: Row(
					children: [
						NavigationRail(
							extended: width >= Breakpoints.desktop,
							selectedIndex: selectedIndex,
							onDestinationSelected: onDestinationSelected,
							labelType: width >= Breakpoints.desktop
									? NavigationRailLabelType.none
									: NavigationRailLabelType.all,
							destinations: destinations
									.map(
										(destination) => NavigationRailDestination(
											icon: destination.icon,
											selectedIcon: destination.selectedIcon,
											label: Text(destination.label),
										),
									)
									.toList(),
						),
						const VerticalDivider(width: 1),
						Expanded(
							flex: detailPanel == null ? 1 : 3,
							child: Column(
								children: [
									_DesktopHeader(title: title),
									Expanded(child: body),
								],
							),
						),
						if (detailPanel != null) ...[
							const VerticalDivider(width: 1),
							SizedBox(
								width: 360,
								child: detailPanel,
							),
						],
					],
				),
				floatingActionButton: floatingActionButton,
			);
		}

		return Scaffold(
			appBar: AppBar(title: Text(title)),
			body: body,
			floatingActionButton: floatingActionButton,
			bottomNavigationBar: destinations.isEmpty
					? null
					: NavigationBar(
							selectedIndex: selectedIndex,
							onDestinationSelected: onDestinationSelected,
							destinations: destinations,
						),
		);
	}
}

class _DesktopHeader extends StatelessWidget {
	const _DesktopHeader({required this.title});

	final String title;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 64,
			padding: const EdgeInsets.symmetric(horizontal: 24),
			alignment: Alignment.centerLeft,
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				border: Border(
					bottom: BorderSide(color: Colors.grey.shade200),
				),
			),
			child: Text(
				title,
				style: Theme.of(context).textTheme.titleLarge?.copyWith(
							fontWeight: FontWeight.w600,
						),
			),
		);
	}
}
