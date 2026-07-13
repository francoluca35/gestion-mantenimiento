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

	Future<void> _start() async {
		if (_started) return;
		final auth = ref.read(authControllerProvider);
		if (!auth.isAuthenticated) return;
		_started = true;

		await FcmService.instance.init(
			onToken: (token) =>
					ref.read(authControllerProvider.notifier).registerFcmToken(token),
			onOpen: (_) {
				final router = GoRouter.maybeOf(context);
				router?.go('/mis-ot');
			},
			onForeground: (title, body) {
				rootScaffoldMessengerKey.currentState?.showSnackBar(
					SnackBar(
						content: Text('$title\n$body'),
						action: SnackBarAction(
							label: 'Ver',
							onPressed: () {
								final router = GoRouter.maybeOf(context);
								router?.go('/mis-ot');
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
