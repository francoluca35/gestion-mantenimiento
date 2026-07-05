import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
	ApiClient({http.Client? client}) : _client = client ?? http.Client();

	final http.Client _client;

	Uri _uri(String path) {
		final normalized = path.startsWith('/') ? path.substring(1) : path;
		return Uri.parse('${AppConfig.apiBaseUrl}/$normalized');
	}

	Future<Map<String, dynamic>> getJson(String path) async {
		final response = await _client.get(_uri(path));
		_ensureSuccess(response);
		return jsonDecode(response.body) as Map<String, dynamic>;
	}

	void _ensureSuccess(http.Response response) {
		if (response.statusCode < 200 || response.statusCode >= 300) {
			throw ApiException(
				statusCode: response.statusCode,
				message: response.body,
			);
		}
	}
}

class ApiException implements Exception {
	ApiException({required this.statusCode, required this.message});

	final int statusCode;
	final String message;

	@override
	String toString() => 'ApiException($statusCode): $message';
}
