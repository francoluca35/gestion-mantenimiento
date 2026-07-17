import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import 'fcm_service.dart';

/// Engancha FCM cuando el usuario ya autenticó (Android).
class FcmBootstrap extends ConsumerStatefulWidget {
	const FcmBootstrap({super.key, required this.child});

	final Widget child;

	@override
	ConsumerState<FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends ConsumerState<FcmBootstrap> {
	var _started = false;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) => _start());
	}

	String _misOtPath(String? otNumero) {
		final n = otNumero?.trim();
		if (n == null || n.isEmpty) return '/mis-ot';
		return '/mis-ot?numero=${Uri.encodeQueryComponent(n)}';
	}

	Future<void> _start() async {
		if (_started) return;
		final auth = ref.read(authControllerProvider);
		if (!auth.isAuthenticated) return;
		_started = true;

		await FcmService.instance.init(
			onToken: (token) =>
					ref.read(authControllerProvider.notifier).registerFcmToken(token),
			onOpen: (otNumero) {
				final router = GoRouter.maybeOf(context);
				router?.go(_misOtPath(otNumero));
			},
			onForeground: (title, body, otNumero) {
				rootScaffoldMessengerKey.currentState?.showSnackBar(
					SnackBar(
						content: Text('$title\n$body'),
						action: SnackBarAction(
							label: 'Ver',
							onPressed: () {
								final router = GoRouter.maybeOf(context);
								router?.go(_misOtPath(otNumero));
							},
						),
						duration: const Duration(seconds: 6),
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		ref.listen(authControllerProvider, (prev, next) {
			if (next.isAuthenticated && !_started) {
				_start();
			}
			if (!next.isAuthenticated) {
				_started = false;
			}
		});
		return widget.child;
	}
}
