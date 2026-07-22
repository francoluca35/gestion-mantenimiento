import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_ui.dart';
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
				AppColors.brandPurple,
			),
			(
				Icons.badge_outlined,
				'Perfiles',
				'Perfiles y derechos',
				'/perfiles',
				AppColors.brandOrange,
			),
			(
				Icons.apartment_outlined,
				'Plantas',
				'Sucursales del sistema',
				'/sucursales',
				AppColors.brandGreenDark,
			),
			(
				Icons.account_tree_outlined,
				'Derechos',
				'Catálogo global (solo lectura)',
				'/derechos',
				AppColors.brandPurpleDark,
			),
		];

		return ListView(
			children: [
				const SikaPageHeader(
					title: 'Configuración',
					subtitle: 'Usuarios, perfiles y plantas',
					icon: Icons.settings_rounded,
				),
				const SizedBox(height: 8),
				...items.map(
					(item) => Padding(
						padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
						child: SikaCard(
							onTap: () => context.push(item.$4),
							child: Row(
								children: [
									Container(
										width: 48,
										height: 48,
										decoration: BoxDecoration(
											color: item.$5.withValues(alpha: 0.12),
											borderRadius: BorderRadius.circular(14),
										),
										child: Icon(item.$1, color: item.$5),
									),
									const SizedBox(width: 16),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													item.$2,
													style: const TextStyle(
														fontWeight: FontWeight.w700,
														color: Colors.white,
														fontSize: 16,
													),
												),
												const SizedBox(height: 4),
												Text(
													item.$3,
													style: const TextStyle(
														color: AppColors.mutedText,
														fontSize: 13,
													),
												),
											],
										),
									),
									Icon(
										Icons.chevron_right_rounded,
										color: AppColors.mutedText.withValues(alpha: 0.6),
									),
								],
							),
						),
					),
				),
			],
		);
	}
}
