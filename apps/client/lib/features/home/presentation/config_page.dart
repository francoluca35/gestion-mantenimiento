import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class ConfigPage extends StatelessWidget {
	const ConfigPage({super.key});

	@override
	Widget build(BuildContext context) {
		final items = [
			(
				Icons.people_outline_rounded,
				'Usuarios',
				'Alta y gestión de usuarios',
				'/usuarios',
			),
			(
				Icons.badge_outlined,
				'Perfiles',
				'Perfiles y derechos',
				'/perfiles',
			),
			(
				Icons.apartment_outlined,
				'Plantas',
				'Sucursales del sistema',
				'/sucursales',
			),
		];

		return ListView(
			padding: const EdgeInsets.all(20),
			children: [
				Text(
					'Configuración',
					style: Theme.of(context).textTheme.titleLarge?.copyWith(
								fontWeight: FontWeight.w700,
							),
				),
				const SizedBox(height: 4),
				Text(
					'Usuarios, perfiles y plantas',
					style: Theme.of(context).textTheme.bodySmall?.copyWith(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
							),
				),
				const SizedBox(height: 20),
				...items.map(
					(item) => Padding(
						padding: const EdgeInsets.only(bottom: 12),
						child: Material(
							color: Theme.of(context).colorScheme.surface,
							borderRadius: BorderRadius.circular(16),
							child: InkWell(
								borderRadius: BorderRadius.circular(16),
								onTap: () => context.push(item.$4),
								child: Container(
									padding: const EdgeInsets.all(16),
									decoration: BoxDecoration(
										borderRadius: BorderRadius.circular(16),
										border: Border.all(
											color: Theme.of(context)
													.colorScheme
													.outlineVariant
													.withValues(alpha: 0.35),
										),
									),
									child: Row(
										children: [
											Container(
												width: 44,
												height: 44,
												decoration: BoxDecoration(
													color: AppColors.primary.withValues(alpha: 0.1),
													borderRadius: BorderRadius.circular(12),
												),
												child: Icon(item.$1, color: AppColors.primary),
											),
											const SizedBox(width: 14),
											Expanded(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															item.$2,
															style: const TextStyle(fontWeight: FontWeight.w700),
														),
														Text(
															item.$3,
															style: Theme.of(context).textTheme.bodySmall,
														),
													],
												),
											),
											const Icon(Icons.chevron_right_rounded),
										],
									),
								),
							),
						),
					),
				),
			],
		);
	}
}
