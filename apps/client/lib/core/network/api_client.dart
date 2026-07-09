import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
	ApiClient({http.Client? client, this.getAccessToken})
			: _client = client ?? http.Client();

	final http.Client _client;
	final Future<String?> Function()? getAccessToken;

	Uri _uri(String path) {
		final normalized = path.startsWith('/') ? path.substring(1) : path;
		return Uri.parse('${AppConfig.apiBaseUrl}/$normalized');
	}

	Future<Map<String, String>> _headers({bool auth = true}) async {
		final headers = <String, String>{
			'Content-Type': 'application/json',
			'Accept': 'application/json',
		};

		if (auth && getAccessToken != null) {
			final token = await getAccessToken!();
			if (token != null && token.isNotEmpty) {
				headers['Authorization'] = 'Bearer $token';
			}
		}

		return headers;
	}

	Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) async {
		final response = await _client.get(
			_uri(path),
			headers: await _headers(auth: auth),
		);
		return _decodeMap(response);
	}

	Future<List<dynamic>> getList(String path, {bool auth = true}) async {
		final response = await _client.get(
			_uri(path),
			headers: await _headers(auth: auth),
		);
		_ensureSuccess(response);
		return jsonDecode(response.body) as List<dynamic>;
	}

	Future<Map<String, dynamic>> postJson(
		String path,
		Map<String, dynamic> body, {
		bool auth = true,
	}) async {
		final response = await _client.post(
			_uri(path),
			headers: await _headers(auth: auth),
			body: jsonEncode(body),
		);
		return _decodeMap(response);
	}

	Future<void> uploadBytes(
		String uploadPath,
		List<int> bytes, {
		required String contentType,
		bool auth = true,
	}) async {
		final normalized = uploadPath.startsWith('/v1/')
				? uploadPath.substring(4)
				: uploadPath.startsWith('/')
						? uploadPath.substring(1)
						: uploadPath;
		final response = await _client.put(
			_uri(normalized),
			headers: {
				...(await _headers(auth: auth)),
				'Content-Type': contentType,
			},
			body: bytes,
		);
		_ensureSuccess(response);
	}

	Future<Map<String, dynamic>> patchJson(
		String path,
		Map<String, dynamic> body,
	) async {
		final response = await _client.patch(
			_uri(path),
			headers: await _headers(),
			body: jsonEncode(body),
		);
		return _decodeMap(response);
	}

	Future<Map<String, dynamic>> putJson(
		String path,
		Map<String, dynamic> body, {
		bool auth = true,
	}) async {
		final response = await _client.put(
			_uri(path),
			headers: await _headers(auth: auth),
			body: jsonEncode(body),
		);
		return _decodeMap(response);
	}

	Future<Map<String, dynamic>> deleteJson(String path) async {
		final response = await _client.delete(
			_uri(path),
			headers: await _headers(),
		);
		return _decodeMap(response);
	}

	Map<String, dynamic> _decodeMap(http.Response response) {
		_ensureSuccess(response);
		if (response.body.isEmpty) {
			return <String, dynamic>{};
		}
		return jsonDecode(response.body) as Map<String, dynamic>;
	}

	void _ensureSuccess(http.Response response) {
		if (response.statusCode < 200 || response.statusCode >= 300) {
			String message = response.body;
			try {
				final decoded = jsonDecode(response.body);
				if (decoded is Map<String, dynamic>) {
					final raw = decoded['message'];
					if (raw is List) {
						message = raw.join(', ');
					} else if (raw is String) {
						message = raw;
					}
				}
			} catch (_) {}
			throw ApiException(statusCode: response.statusCode, message: message);
		}
	}
}

class ApiException implements Exception {
	ApiException({required this.statusCode, required this.message});

	final int statusCode;
	final String message;

	@override
	String toString() => message;
}
