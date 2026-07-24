import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'breakpoints.dart';
import 'shell_back_scope.dart';

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
		this.subtitle,
		this.headerActions = const [],
	});

	final String title;
	final String? subtitle;
	final Widget body;
	final int selectedIndex;
	final ValueChanged<int>? onDestinationSelected;
	final List<NavigationDestination> destinations;
	final Widget? floatingActionButton;
	final Widget? detailPanel;
	final List<Widget> headerActions;

	@override
	Widget build(BuildContext context) {
		final width = MediaQuery.sizeOf(context).width;
		final isDesktop = Breakpoints.isDesktop(width);
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final pageBg = AppColors.backgroundDark;
		final sideBg = AppColors.explorerPanel;
		final scheme = Theme.of(context).colorScheme;

		if (isDesktop) {
			return Scaffold(
				backgroundColor: pageBg,
				floatingActionButton: floatingActionButton,
				body: Row(
					children: [
						SizedBox(
							width: width >= Breakpoints.desktop ? 260 : 88,
							child: Material(
								color: sideBg,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										Padding(
											padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
											child: width >= Breakpoints.desktop
													? Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Text(
																	'SIKA',
																	style: Theme.of(context).textTheme.titleLarge?.copyWith(
																				fontWeight: FontWeight.w800,
																				color: AppColors.primary,
																			),
																),
																const SizedBox(height: 4),
																Text(
																	'Mantenimiento',
																	style: Theme.of(context).textTheme.bodySmall?.copyWith(
																				color: scheme.onSurfaceVariant,
																			),
																),
															],
														)
													: const Icon(Icons.factory_rounded, color: AppColors.primary),
										),
										Expanded(
											child: ListView.builder(
												padding: const EdgeInsets.symmetric(horizontal: 10),
												itemCount: destinations.length,
												itemBuilder: (context, index) {
													final item = destinations[index];
													final selected = index == selectedIndex;
													final extended = width >= Breakpoints.desktop;

													return Padding(
														padding: const EdgeInsets.only(bottom: 4),
														child: Material(
															color: selected
																	? AppColors.primary.withValues(alpha: 0.12)
																	: Colors.transparent,
															borderRadius: BorderRadius.circular(12),
															child: InkWell(
																borderRadius: BorderRadius.circular(12),
																onTap: () => onDestinationSelected?.call(index),
																child: Padding(
																	padding: EdgeInsets.symmetric(
																		horizontal: extended ? 14 : 0,
																		vertical: 12,
																	),
																	child: extended
																			? Row(
																					children: [
																						Icon(
																							(selected
																											? item.selectedIcon
																											: item.icon) is Icon
																									? ((selected
																													? item.selectedIcon
																													: item.icon) as Icon)
																											.icon
																									: Icons.circle,
																							size: 20,
																							color: selected
																									? AppColors.primary
																									: scheme.onSurfaceVariant,
																						),
																						const SizedBox(width: 12),
																						Expanded(
																							child: Text(
																								item.label,
																								style: TextStyle(
																									fontWeight: selected
																											? FontWeight.w700
																											: FontWeight.w500,
																									color: selected
																											? AppColors.primary
																											: null,
																								),
																							),
																						),
																					],
																				)
																			: Column(
																					children: [
																						Icon(
																							(selected
																											? item.selectedIcon
																											: item.icon) is Icon
																									? ((selected
																													? item.selectedIcon
																													: item.icon) as Icon)
																											.icon
																									: Icons.circle,
																							size: 20,
																							color: selected
																									? AppColors.primary
																									: scheme.onSurfaceVariant,
																						),
																						const SizedBox(height: 4),
																						Text(
																							item.label,
																							style: TextStyle(
																								fontSize: 10,
																								fontWeight: selected
																										? FontWeight.w700
																										: FontWeight.w500,
																								color: selected
																										? AppColors.primary
																										: null,
																							),
																						),
																					],
																				),
																),
															),
														),
													);
												},
											),
										),
									],
								),
							),
						),
						VerticalDivider(
							width: 1,
							color: scheme.outlineVariant.withValues(alpha: 0.35),
						),
						Expanded(
							flex: detailPanel == null ? 1 : 3,
							child: Column(
								children: [
									_DesktopHeader(
										title: title,
										subtitle: subtitle,
										actions: headerActions,
									),
									Expanded(child: body),
								],
							),
						),
						if (detailPanel != null) ...[
							VerticalDivider(
								width: 1,
								color: scheme.outlineVariant.withValues(alpha: 0.35),
							),
							SizedBox(width: 360, child: detailPanel),
						],
					],
				),
			);
		}

		return Scaffold(
			backgroundColor: pageBg,
			appBar: AppBar(
				automaticallyImplyLeading: false,
				leading: const ShellBackButton(),
				title: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(title),
						if (subtitle != null)
							Text(
								subtitle!,
								style: Theme.of(context).textTheme.bodySmall,
							),
					],
				),
				actions: headerActions,
			),
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
	const _DesktopHeader({
		required this.title,
		this.subtitle,
		this.actions = const [],
	});

	final String title;
	final String? subtitle;
	final List<Widget> actions;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 72,
			padding: const EdgeInsets.symmetric(horizontal: 24),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				border: Border(
					bottom: BorderSide(
						color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
					),
				),
			),
			child: Row(
				children: [
					const ShellBackButton(),
					const SizedBox(width: 8),
					Expanded(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									title,
									style: Theme.of(context).textTheme.titleLarge?.copyWith(
												fontWeight: FontWeight.w700,
											),
								),
								if (subtitle != null) ...[
									const SizedBox(height: 2),
									Text(
										subtitle!,
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: Theme.of(context).colorScheme.onSurfaceVariant,
												),
									),
								],
							],
						),
					),
					...actions,
				],
			),
		);
	}
}
