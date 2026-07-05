import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class PerfilPage extends ConsumerWidget {
	const PerfilPage({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;

		return ListView(
			padding: const EdgeInsets.all(20),
			children: [
				Container(
					padding: const EdgeInsets.all(24),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surface,
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
						),
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									CircleAvatar(
										radius: 28,
										backgroundColor: AppColors.primary.withValues(alpha: 0.12),
										child: Text(
											(user?.nombreUsuario.isNotEmpty == true)
													? user!.nombreUsuario[0].toUpperCase()
													: 'U',
											style: const TextStyle(
												color: AppColors.primary,
												fontWeight: FontWeight.w700,
												fontSize: 20,
											),
										),
									),
									const SizedBox(width: 16),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													user?.nombreUsuario ?? '',
													style: Theme.of(context).textTheme.titleLarge?.copyWith(
																fontWeight: FontWeight.w700,
															),
												),
												Text(
													user?.perfilNombre ??
															(user?.esAdministrador == true
																	? 'Administrador'
																	: 'Sin perfil'),
												),
											],
										),
									),
								],
							),
							const SizedBox(height: 20),
							Wrap(
								spacing: 12,
								runSpacing: 12,
								children: [
									_InfoChip(
										label: 'Planta',
										value: user?.sucursalNombre ?? 'Sin planta',
									),
									_InfoChip(
										label: 'Derechos',
										value: '${user?.derechos.length ?? 0}',
									),
									_InfoChip(
										label: 'Admin',
										value: user?.esAdministrador == true ? 'Sí' : 'No',
									),
								],
							),
						],
					),
				),
				const SizedBox(height: 16),
				SizedBox(
					width: double.infinity,
					child: FilledButton.tonalIcon(
						onPressed: () async {
							await ref.read(authControllerProvider.notifier).logout();
							if (context.mounted) context.go('/login');
						},
						icon: const Icon(Icons.logout_rounded),
						label: const Text('Cerrar sesión'),
					),
				),
			],
		);
	}
}

class _InfoChip extends StatelessWidget {
	const _InfoChip({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(label, style: Theme.of(context).textTheme.bodySmall),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
				],
			),
		);
	}
}
