import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/open_print_html.dart';
import '../../auth/application/auth_controller.dart';

Future<void> abrirPdfOt(WidgetRef ref, String otId) async {
	final data = await ref.read(apiClientProvider).getJson('ot/$otId/pdf');
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
