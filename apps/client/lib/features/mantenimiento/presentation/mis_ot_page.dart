import 'package:flutter/material.dart';

import 'ot_page.dart';

/// Flujo móvil técnico — solo OT asignadas al usuario.
class MisOtPage extends StatelessWidget {
	const MisOtPage({super.key});

	@override
	Widget build(BuildContext context) {
		return const OtPage(misOtOnly: true);
	}
}
