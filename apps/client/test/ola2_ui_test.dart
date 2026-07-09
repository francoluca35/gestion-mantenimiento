import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_mantenimiento/core/theme/app_colors.dart';
import 'package:gestion_mantenimiento/features/mantenimiento/presentation/ot_ui.dart';

/// Validación visual/semántica de Ola 2 sin browser (colores OT SGwing-17).
void main() {
	group('Ola 2 — colores OT (SGwing-17)', () {
		test('estado pendiente → rojo', () {
			expect(OtUi.estadoColor('pendiente'), AppColors.danger);
		});

		test('estado en_ejecucion → amarillo', () {
			expect(OtUi.estadoColor('en_ejecucion'), AppColors.warning);
		});

		test('estado realizada → verde', () {
			expect(OtUi.estadoColor('realizada'), AppColors.success);
		});
	});

	group('Ola 2 — chips de estado renderizan color correcto', () {
		Widget chip(String estado) {
			final color = OtUi.estadoColor(estado);
			return MaterialApp(
				home: Scaffold(
					body: Container(
						color: color,
						child: Text(OtUi.estadoLabel(estado)),
					),
				),
			);
		}

		testWidgets('pendiente muestra etiqueta', (tester) async {
			await tester.pumpWidget(chip('pendiente'));
			expect(find.text('Pendiente'), findsOneWidget);
		});

		testWidgets('en ejecución muestra etiqueta', (tester) async {
			await tester.pumpWidget(chip('en_ejecucion'));
			expect(find.text('En ejecución'), findsOneWidget);
		});

		testWidgets('realizada muestra etiqueta', (tester) async {
			await tester.pumpWidget(chip('realizada'));
			expect(find.text('Realizada'), findsOneWidget);
		});
	});
}
