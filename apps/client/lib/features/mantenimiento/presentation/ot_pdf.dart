import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/open_pdf_bytes.dart';
import '../../../core/utils/open_print_html.dart';
import '../../auth/application/auth_controller.dart';

Future<void> abrirPdfOt(WidgetRef ref, String otId) async {
	final api = ref.read(apiClientProvider);
	try {
		final bytes = await api.getBytes('ot/$otId/pdf/file');
		final meta = await api.getJson('ot/$otId/pdf');
		final numero = meta['numero']?.toString() ?? otId;
		await openPdfBytes(bytes, 'OT-$numero.pdf');
		return;
	} catch (_) {
		// Fallback HTML imprimible si Puppeteer no está disponible.
	}

	final data = await api.getJson('ot/$otId/pdf');
	final html = data['html'] as String?;
	if (html == null || html.isEmpty) {
		throw Exception('No se pudo generar el PDF de la OT');
	}
	openHtmlForPrint(html);
}

Future<void> abrirPdfOtList(WidgetRef ref, List<String> otIds) async {
	for (final id in otIds) {
		await abrirPdfOt(ref, id);
	}
}
