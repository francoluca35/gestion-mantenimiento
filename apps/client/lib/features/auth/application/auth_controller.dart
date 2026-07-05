import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

class AuthState {
	const AuthState({
		this.session,
		this.loading = false,
		this.error,
		this.bootstrapped = false,
	});

	final AuthSession? session;
	final bool loading;
	final String? error;
	final bool bootstrapped;

	bool get isAuthenticated => session != null;

	AuthState copyWith({
		AuthSession? session,
		bool? loading,
		String? error,
		bool? bootstrapped,
		bool clearSession = false,
		bool clearError = false,
	}) {
		return AuthState(
			session: clearSession ? null : (session ?? this.session),
			loading: loading ?? this.loading,
			error: clearError ? null : (error ?? this.error),
			bootstrapped: bootstrapped ?? this.bootstrapped,
		);
	}
}

class AuthController extends StateNotifier<AuthState> {
	AuthController(this._prefs)
			: super(const AuthState()) {
		_api = ApiClient(getAccessToken: () async => state.session?.accessToken);
		_repository = AuthRepository(_api);
		_bootstrap();
	}

	final SharedPreferences _prefs;
	late final ApiClient _api;
	late final AuthRepository _repository;

	ApiClient get apiClient => _api;

	Future<void> _bootstrap() async {
		final accessToken = _prefs.getString(_accessTokenKey);
		final refreshToken = _prefs.getString(_refreshTokenKey);

		if (accessToken == null || refreshToken == null) {
			state = state.copyWith(bootstrapped: true);
			return;
		}

		state = state.copyWith(
			session: AuthSession(
				accessToken: accessToken,
				refreshToken: refreshToken,
				usuario: const AuthUser(
					id: '',
					nombreUsuario: '',
					email: null,
					esAdministrador: false,
					supervisaSucursales: false,
					derechos: [],
					sucursalId: null,
					sucursalNombre: null,
					perfilNombre: null,
				),
			),
		);

		try {
			final usuario = await _repository.me();
			state = state.copyWith(
				session: AuthSession(
					accessToken: accessToken,
					refreshToken: refreshToken,
					usuario: usuario,
				),
				bootstrapped: true,
			);
		} catch (_) {
			await _clearTokens();
			state = state.copyWith(clearSession: true, bootstrapped: true);
		}
	}

	Future<bool> login({
		required String nombreUsuario,
		required String clave,
	}) async {
		state = state.copyWith(loading: true, clearError: true);
		try {
			final session = await _repository.login(
				nombreUsuario: nombreUsuario.trim(),
				clave: clave,
			);
			await _prefs.setString(_accessTokenKey, session.accessToken);
			await _prefs.setString(_refreshTokenKey, session.refreshToken);
			state = state.copyWith(
				session: session,
				loading: false,
				bootstrapped: true,
			);
			return true;
		} catch (error) {
			state = state.copyWith(
				loading: false,
				error: error.toString(),
			);
			return false;
		}
	}

	Future<void> logout() async {
		final refreshToken = state.session?.refreshToken;
		try {
			if (refreshToken != null) {
				await _repository.logout(refreshToken);
			}
		} catch (_) {}
		await _clearTokens();
		state = state.copyWith(clearSession: true, clearError: true);
	}

	Future<void> _clearTokens() async {
		await _prefs.remove(_accessTokenKey);
		await _prefs.remove(_refreshTokenKey);
	}
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
	throw UnimplementedError('SharedPreferences no inicializado');
});

final authControllerProvider =
		StateNotifierProvider<AuthController, AuthState>((ref) {
	final prefs = ref.watch(sharedPreferencesProvider);
	return AuthController(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
	return ref.watch(authControllerProvider.notifier).apiClient;
});
