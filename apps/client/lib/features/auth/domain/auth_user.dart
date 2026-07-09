class AuthUser {
	const AuthUser({
		required this.id,
		required this.nombreUsuario,
		required this.email,
		required this.esAdministrador,
		required this.supervisaSucursales,
		required this.derechos,
		required this.sucursalId,
		required this.sucursalNombre,
		required this.perfilNombre,
	});

	final String id;
	final String nombreUsuario;
	final String? email;
	final bool esAdministrador;
	final bool supervisaSucursales;
	final List<String> derechos;
	final String? sucursalId;
	final String? sucursalNombre;
	final String? perfilNombre;

	bool tieneDerecho(String codigo) {
		if (esAdministrador) return true;
		return derechos.contains(codigo);
	}

	/// Perfil operativo de campo — solo Mis OT, sin emisión ni supervisión.
	bool get esTecnico {
		if (esAdministrador || supervisaSucursales) return false;
		final perfil = perfilNombre?.toLowerCase().trim() ?? '';
		if (perfil.contains('técnico') || perfil.contains('tecnico')) {
			return true;
		}
		return tieneDerecho('programacion.ordenes_trabajo.buscar_y_actualizar') &&
				!tieneDerecho('programacion.ordenes_trabajo.emitir_no_periodica') &&
				!tieneDerecho('programacion.ordenes_trabajo.emitir_periodica') &&
				!tieneDerecho('programacion.solicitudes_trabajo.listar') &&
				!tieneDerecho('configuracion.usuarios.listar');
	}

	factory AuthUser.fromJson(Map<String, dynamic> json) {
		final sucursal = json['sucursal'] as Map<String, dynamic>?;
		final perfil = json['perfil'] as Map<String, dynamic>?;
		final derechosRaw = json['derechos'] as List<dynamic>? ?? [];

		return AuthUser(
			id: json['id'] as String,
			nombreUsuario: json['nombreUsuario'] as String,
			email: json['email'] as String?,
			esAdministrador: json['esAdministrador'] as bool? ?? false,
			supervisaSucursales: json['supervisaSucursales'] as bool? ?? false,
			derechos: derechosRaw.map((item) => item.toString()).toList(),
			sucursalId: (json['sucursalId'] as String?) ?? (sucursal?['id'] as String?),
			sucursalNombre: sucursal?['nombre'] as String?,
			perfilNombre: perfil?['nombre'] as String?,
		);
	}
}

class AuthSession {
	const AuthSession({
		required this.accessToken,
		required this.refreshToken,
		required this.usuario,
	});

	final String accessToken;
	final String refreshToken;
	final AuthUser usuario;

	factory AuthSession.fromJson(Map<String, dynamic> json) {
		return AuthSession(
			accessToken: json['accessToken'] as String,
			refreshToken: json['refreshToken'] as String,
			usuario: AuthUser.fromJson(json['usuario'] as Map<String, dynamic>),
		);
	}
}
