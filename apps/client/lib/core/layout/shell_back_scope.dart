import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../notifications/fcm_service.dart';

/// Acceso a la navegación atrás del shell (para flecha junto al título).
class ShellBack extends InheritedWidget {
	const ShellBack({
		super.key,
		required this.goBack,
		required this.canGoBack,
		required super.child,
	});

	final VoidCallback goBack;
	final bool canGoBack;

	static ShellBack? maybeOf(BuildContext context) {
		return context.dependOnInheritedWidgetOfExactType<ShellBack>();
	}

	static ShellBack of(BuildContext context) {
		final scope = maybeOf(context);
		assert(scope != null, 'ShellBack no encontrado en el árbol');
		return scope!;
	}

	@override
	bool updateShouldNotify(ShellBack oldWidget) {
		return canGoBack != oldWidget.canGoBack;
	}
}

/// Flecha atrás para colocar al lado del título de cada pantalla.
class ShellBackButton extends StatelessWidget {
	const ShellBackButton({
		super.key,
		this.color,
		this.size = 24,
	});

	final Color? color;
	final double size;

	@override
	Widget build(BuildContext context) {
		final back = ShellBack.maybeOf(context);
		return IconButton(
			tooltip: 'Atrás',
			padding: EdgeInsets.zero,
			constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
			visualDensity: VisualDensity.compact,
			onPressed: back == null ? null : back.goBack,
			icon: Icon(
				Icons.arrow_back_rounded,
				color: color ?? Theme.of(context).colorScheme.onSurface,
				size: size,
			),
		);
	}
}

/// Envuelve el shell autenticado:
/// - expone [ShellBack] / [ShellBackButton] para la flecha junto al título
/// - el botón atrás del sistema pide confirmación (doble toque) para salir en raíz
class ShellBackScope extends StatefulWidget {
	const ShellBackScope({
		super.key,
		required this.location,
		required this.homeRoute,
		required this.child,
	});

	final String location;
	final String homeRoute;
	final Widget child;

	@override
	State<ShellBackScope> createState() => _ShellBackScopeState();
}

class _ShellBackScopeState extends State<ShellBackScope> {
	DateTime? _lastExitAttempt;

	bool get _isRoot {
		final loc = _normalize(widget.location);
		final home = _normalize(widget.homeRoute);
		return loc == home || loc == '/' || loc == '/login';
	}

	String _normalize(String path) {
		if (path.length > 1 && path.endsWith('/')) {
			return path.substring(0, path.length - 1);
		}
		return path;
	}

	String? _parentRoute(String location) {
		final loc = _normalize(location);
		final home = _normalize(widget.homeRoute);

		if (loc.startsWith('/ot/gantt')) {
			return home == '/mis-ot' ? '/mis-ot' : '/ot';
		}
		if (loc.startsWith('/ot/graficos')) return home;
		if (loc.startsWith('/ot/necesarias')) return home;
		if (loc.startsWith('/ot/emitir-no-periodica') ||
				loc.startsWith('/ot/emitir-periodica')) {
			return home == '/mis-ot' ? '/mis-ot' : '/ot';
		}
		if (loc.contains('/derechos')) return '/perfiles';
		if (loc.startsWith('/usuarios') ||
				loc.startsWith('/perfiles') ||
				loc.startsWith('/sucursales') ||
				loc.startsWith('/derechos')) {
			return '/config';
		}
		if (loc.startsWith('/panol/') && loc != '/panol') return '/panol';
		if (loc == '/solicitudes-materiales') return home;
		if (loc == '/ot' ||
				loc == '/planta' ||
				loc == '/procedimientos' ||
				loc == '/solicitudes' ||
				loc == '/stock' ||
				loc == '/contadores' ||
				loc == '/config' ||
				loc == '/perfil' ||
				loc == '/panol' ||
				loc.startsWith('/panol/dashboard') ||
				loc.startsWith('/panol/stock') ||
				loc.startsWith('/panol/pedidos') ||
				loc.startsWith('/panol/seguimiento')) {
			return loc == home ? null : home;
		}
		return loc == home ? null : home;
	}

	bool get _canGoBack {
		final navigator = Navigator.of(context);
		if (navigator.canPop()) return true;
		final router = GoRouter.of(context);
		if (router.canPop()) return true;
		final parent = _parentRoute(widget.location);
		return parent != null && _normalize(parent) != _normalize(widget.location);
	}

	bool _tryNavigateBack() {
		final navigator = Navigator.of(context);
		if (navigator.canPop()) {
			navigator.pop();
			return true;
		}
		final router = GoRouter.of(context);
		if (router.canPop()) {
			router.pop();
			return true;
		}
		final parent = _parentRoute(widget.location);
		if (parent != null && _normalize(parent) != _normalize(widget.location)) {
			context.go(parent);
			return true;
		}
		return false;
	}

	void _onUiBack() {
		_tryNavigateBack();
	}

	void _onSystemBack() {
		if (_tryNavigateBack()) return;
		if (!_isRoot) return;

		final now = DateTime.now();
		final previous = _lastExitAttempt;
		if (previous == null || now.difference(previous) > const Duration(seconds: 2)) {
			_lastExitAttempt = now;
			rootScaffoldMessengerKey.currentState
				?..hideCurrentSnackBar()
				..showSnackBar(
					const SnackBar(
						content: Text('Presioná atrás otra vez para salir'),
						duration: Duration(seconds: 2),
					),
				);
			return;
		}
		SystemNavigator.pop();
	}

	@override
	Widget build(BuildContext context) {
		return ShellBack(
			goBack: _onUiBack,
			canGoBack: _canGoBack,
			child: PopScope(
				canPop: false,
				onPopInvokedWithResult: (didPop, result) {
					if (didPop) return;
					_onSystemBack();
				},
				child: widget.child,
			),
		);
	}
}
