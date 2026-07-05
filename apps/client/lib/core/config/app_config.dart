class AppConfig {
	const AppConfig._();

	/// Emulador Android: 10.0.2.2 apunta al localhost del host.
	/// Web / desktop: localhost.
	/// Dispositivo físico: IP de tu PC en la red.
	static const String apiBaseUrl = String.fromEnvironment(
		'API_BASE_URL',
		defaultValue: 'http://localhost:3000/v1',
	);

	static const String appName = 'Gestión de Mantenimiento';
}
