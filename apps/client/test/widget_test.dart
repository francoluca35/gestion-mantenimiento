import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_mantenimiento/app.dart';
import 'package:gestion_mantenimiento/features/auth/application/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
	testWidgets('muestra pantalla de login', (tester) async {
		SharedPreferences.setMockInitialValues({});
		final prefs = await SharedPreferences.getInstance();

		await tester.pumpWidget(
			ProviderScope(
				overrides: [
					sharedPreferencesProvider.overrideWithValue(prefs),
				],
				child: const GestionMantenimientoApp(),
			),
		);

		await tester.pumpAndSettle();

		expect(find.text('Gestión de Mantenimiento'), findsOneWidget);
		expect(find.text('Ingresar'), findsOneWidget);
	});
}
