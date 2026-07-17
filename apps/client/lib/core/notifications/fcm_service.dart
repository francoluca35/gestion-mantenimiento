import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

/// Handler de background — debe ser top-level y anotado.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
	await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
	debugPrint('[FCM:bg] ${message.notification?.title} ${message.data}');
}

typedef FcmTokenCallback = Future<void> Function(String token);
typedef FcmOpenCallback = void Function(String? otNumero);
typedef FcmForegroundCallback = void Function(
	String title,
	String body,
	String? otNumero,
);

/// Push FCM para Android (web queda fuera de alcance en Sprint 4).
class FcmService {
	FcmService._();
	static final FcmService instance = FcmService._();

	bool _initialized = false;
	FcmTokenCallback? _onToken;
	FcmOpenCallback? _onOpen;
	FcmForegroundCallback? _onForeground;

	Future<void> init({
		required FcmTokenCallback onToken,
		required FcmOpenCallback onOpen,
		FcmForegroundCallback? onForeground,
	}) async {
		if (kIsWeb || _initialized) return;

		_onToken = onToken;
		_onOpen = onOpen;
		_onForeground = onForeground;

		FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

		final messaging = FirebaseMessaging.instance;
		await messaging.requestPermission(
			alert: true,
			badge: true,
			sound: true,
		);

		await messaging.setForegroundNotificationPresentationOptions(
			alert: true,
			badge: true,
			sound: true,
		);

		FirebaseMessaging.onMessage.listen((message) {
			final title = message.notification?.title ?? 'OT asignada';
			final body = message.notification?.body ?? 'Tenés una nueva orden de trabajo';
			_onForeground?.call(title, body, message.data['otNumero']);
		});

		FirebaseMessaging.onMessageOpenedApp.listen((message) {
			_onOpen?.call(message.data['otNumero']);
		});

		final initial = await messaging.getInitialMessage();
		if (initial != null) {
			_onOpen?.call(initial.data['otNumero']);
		}

		messaging.onTokenRefresh.listen((token) async {
			await _onToken?.call(token);
		});

		final token = await messaging.getToken();
		if (token != null && token.isNotEmpty) {
			await _onToken?.call(token);
		}

		_initialized = true;
		debugPrint('[FCM] listeners activos');
	}

	Future<void> syncToken() async {
		if (kIsWeb) return;
		try {
			final token = await FirebaseMessaging.instance.getToken();
			if (token != null && token.isNotEmpty) {
				await _onToken?.call(token);
			}
		} catch (error) {
			debugPrint('[FCM] syncToken: $error');
		}
	}
}

/// Claves globales para snackbars / navegación desde FCM.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
