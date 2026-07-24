import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytesFile(String filename, List<int> bytes, String mimeType) {
	final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
	final url = html.Url.createObjectUrlFromBlob(blob);
	final anchor = html.AnchorElement(href: url)
		..setAttribute('download', filename)
		..click();
	html.Url.revokeObjectUrl(url);
	anchor.remove();
}
