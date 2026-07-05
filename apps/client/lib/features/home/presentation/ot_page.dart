import 'package:flutter/material.dart';

class OtPage extends StatelessWidget {
	const OtPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: ConstrainedBox(
				constraints: const BoxConstraints(maxWidth: 480),
				child: Container(
					margin: const EdgeInsets.all(20),
					padding: const EdgeInsets.all(28),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surface,
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
						),
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Container(
								width: 56,
								height: 56,
								decoration: BoxDecoration(
									color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(16),
								),
								child: const Icon(Icons.assignment_rounded, color: Color(0xFF7C3AED)),
							),
							const SizedBox(height: 16),
							Text(
								'Órdenes de trabajo',
								style: Theme.of(context).textTheme.titleLarge?.copyWith(
											fontWeight: FontWeight.w700,
										),
							),
							const SizedBox(height: 8),
							Text(
								'Este es el corazón del sistema (M3). Se implementa después de Planta.',
								textAlign: TextAlign.center,
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(
											color: Theme.of(context).colorScheme.onSurfaceVariant,
										),
							),
						],
					),
				),
			),
		);
	}
}
