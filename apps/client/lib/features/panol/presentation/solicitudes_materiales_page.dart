import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import 'pedidos_page.dart';

/// Compat: admins / nav antigua. Pañoleros van a `/panol/pedidos`.
class SolicitudesMaterialesPage extends ConsumerWidget {
	const SolicitudesMaterialesPage({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		if (user?.esPanolero == true) {
			WidgetsBinding.instance.addPostFrameCallback((_) {
				if (context.mounted) context.go('/panol/pedidos');
			});
			return const Scaffold(
				body: Center(child: CircularProgressIndicator()),
			);
		}
		return const PedidosPage();
	}
}
