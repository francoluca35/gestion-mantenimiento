import '../../../core/network/api_client.dart';
import '../domain/auth_user.dart';

class AuthRepository {
	AuthRepository(this._api);

	final ApiClient _api;

	Future<AuthSession> login({
		required String nombreUsuario,
		required String clave,
	}) async {
		final json = await _api.postJson(
			'auth/login',
			{
				'nombreUsuario': nombreUsuario,
				'clave': clave,
			},
			auth: false,
		);
		return AuthSession.fromJson(json);
	}

	Future<AuthUser> me() {
		return _api.getJson('auth/me').then(AuthUser.fromJson);
	}

	Future<void> logout(String refreshToken) async {
		await _api.postJson('auth/logout', {'refreshToken': refreshToken});
	}
}
