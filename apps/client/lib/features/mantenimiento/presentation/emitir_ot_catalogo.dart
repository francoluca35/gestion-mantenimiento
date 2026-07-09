import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

class EmitirOtCatalogo {
	const EmitirOtCatalogo({
		required this.equipos,
		required this.procedimientos,
		required this.tecnicos,
	});

	final List<Map<String, dynamic>> equipos;
	final List<Map<String, dynamic>> procedimientos;
	final List<Map<String, dynamic>> tecnicos;

	static Future<EmitirOtCatalogo> cargar(WidgetRef ref) async {
		final api = ref.read(apiClientProvider);
		final equipos = (await api.getList('equipos')).cast<Map<String, dynamic>>();
		final procedimientos =
				(await api.getList('procedimientos')).cast<Map<String, dynamic>>();
		final tecnicos =
				(await api.getList('ot/tecnicos')).cast<Map<String, dynamic>>();

		return EmitirOtCatalogo(
			equipos: equipos,
			procedimientos: procedimientos,
			tecnicos: tecnicos,
		);
	}

	List<Map<String, dynamic>> procedimientosPeriodicos() {
		return procedimientos
				.where(
					(p) =>
							p['tipo'] == 'preventivo' &&
							p['periodicidadTipo'] == 'tiempo' &&
							p['periodicidadValor'] != null,
				)
				.toList();
	}
}
