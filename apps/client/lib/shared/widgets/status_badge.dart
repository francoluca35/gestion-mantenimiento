import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
	const StatusBadge({super.key, required this.estado});

	final String estado;

	@override
	Widget build(BuildContext context) {
		final config = _configFor(estado);

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
			decoration: BoxDecoration(
				color: config.color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				config.label,
				style: TextStyle(
					color: config.color,
					fontSize: 12,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}

	_BadgeConfig _configFor(String estado) {
		switch (estado) {
			case 'pendiente':
				return const _BadgeConfig('Pendiente', AppColors.warning);
			case 'pendiente_pañol':
				return const _BadgeConfig('Pañol', Colors.deepOrange);
			case 'en_ejecucion':
				return const _BadgeConfig('En ejecución', AppColors.primary);
			case 'realizada':
				return const _BadgeConfig('Realizada', AppColors.success);
			case 'anulada':
				return const _BadgeConfig('Anulada', AppColors.danger);
			default:
				return const _BadgeConfig('—', AppColors.secondary);
		}
	}
}

class _BadgeConfig {
	const _BadgeConfig(this.label, this.color);

	final String label;
	final Color color;
}
