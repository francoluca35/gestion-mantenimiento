import 'dart:html' as html;

void openHtmlForPrint(String htmlContent) {
	final blob = html.Blob([htmlContent], 'text/html');
	final url = html.Url.createObjectUrlFromBlob(blob);
	html.window.open(url, '_blank');
}
