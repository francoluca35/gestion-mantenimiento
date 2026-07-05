import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_mantenimiento/app.dart';

void main() {
	testWidgets('muestra pantalla de login', (tester) async {
		await tester.pumpWidget(
			const ProviderScope(
				child: GestionMantenimientoApp(),
			),
		);

		expect(find.text('Gestión de Mantenimiento'), findsOneWidget);
		expect(find.text('Ingresar'), findsOneWidget);
	});
}
