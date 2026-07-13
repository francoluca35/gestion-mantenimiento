import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Colores y etiquetas OT — alineado con SGwing-17 (verde / rojo / amarillo).
class OtUi {
	const OtUi._();

	static String prioridadLabel(String prioridad) {
		return switch (prioridad) {
			'baja' => 'Baja',
			'media' => 'Media',
			'alta' => 'Alta',
			'urgente' => 'Urgente',
			_ => prioridad,
		};
	}

	static Color prioridadColor(String prioridad) {
		return switch (prioridad) {
			'baja' => AppColors.secondary,
			'media' => AppColors.primary,
			'alta' => AppColors.warning,
			'urgente' => AppColors.danger,
			_ => AppColors.secondary,
		};
	}

	static String estadoLabel(String estado) {
		return switch (estado) {
			'pendiente' => 'Pendiente',
			'en_ejecucion' => 'En ejecución',
			'realizada' => 'Realizada',
			'anulada' => 'Anulada',
			'necesaria_de_emitir' => 'Por emitir',
			'pendiente_panol' => 'Pend. pañol',
			_ => estado,
		};
	}

	/// Verde realizada · rojo pendiente · amarillo en ejecución.
	static Color estadoColor(String estado) {
		return switch (estado) {
			'pendiente' => AppColors.danger,
			'en_ejecucion' => AppColors.warning,
			'realizada' => AppColors.success,
			'anulada' => AppColors.secondary,
			'necesaria_de_emitir' => AppColors.primary,
			'pendiente_panol' => AppColors.secondary,
			_ => AppColors.secondary,
		};
	}

	static Color estadoSurface(String estado) {
		return estadoColor(estado).withValues(alpha: 0.12);
	}

	static IconData tipoIcon(String tipo) {
		return switch (tipo) {
			'preventivo' => Icons.schedule_rounded,
			'correctivo' => Icons.build_circle_outlined,
			'predictivo' => Icons.insights_rounded,
			'mejora' => Icons.trending_up_rounded,
			_ => Icons.assignment_outlined,
		};
	}

	static Color tipoColor(String tipo) {
		return switch (tipo) {
			'preventivo' => AppColors.primary,
			'correctivo' => AppColors.danger,
			'predictivo' => AppColors.accent,
			'mejora' => AppColors.success,
			_ => AppColors.secondary,
		};
	}

	/// Duración estimada del procedimiento (GUT / HH planificada).
	static String formatDuracionMinutos(dynamic minutos) {
		if (minutos == null) return '—';
		final total = minutos is num ? minutos.toInt() : int.tryParse('$minutos');
		if (total == null || total <= 0) return '—';
		final h = total ~/ 60;
		final m = total % 60;
		if (h > 0 && m > 0) return '${h}h ${m}m';
		if (h > 0) return '${h}h';
		return '${m}m';
	}
}
