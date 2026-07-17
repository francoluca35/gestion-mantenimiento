import 'package:flutter/material.dart';

import 'ot_page.dart';

/// Flujo móvil técnico — solo OT asignadas al usuario.
class MisOtPage extends StatelessWidget {
	const MisOtPage({super.key, this.numeroInicial});

	/// Nº de OT a abrir al cargar (p. ej. desde push FCM).
	final String? numeroInicial;

	@override
	Widget build(BuildContext context) {
		return OtPage(
			misOtOnly: true,
			numeroInicial: numeroInicial,
		);
	}
}
