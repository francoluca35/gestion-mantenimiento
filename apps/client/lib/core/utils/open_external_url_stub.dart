import 'package:flutter/services.dart';

/// En plataformas sin navegador embebido, copia el enlace al portapapeles.
void openExternalUrl(String url) {
	Clipboard.setData(ClipboardData(text: url));
}
