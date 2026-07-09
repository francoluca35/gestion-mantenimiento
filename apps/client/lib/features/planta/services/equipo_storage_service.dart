import '../../../core/network/api_client.dart';

class EquipoDocumento {
	const EquipoDocumento({
		required this.id,
		required this.nombre,
		required this.tipo,
		required this.storageKey,
		this.contentType,
		this.url,
	});

	final String id;
	final String nombre;
	final String tipo;
	final String storageKey;
	final String? contentType;
	final String? url;

	factory EquipoDocumento.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
		final key = json['storageKey'] as String;
		return EquipoDocumento(
			id: json['id'] as String,
			nombre: json['nombre'] as String,
			tipo: json['tipo'] as String? ?? 'otro',
			storageKey: key,
			contentType: json['contentType'] as String?,
			url: baseUrl != null ? '$baseUrl/storage/files/${Uri.encodeComponent(key)}' : null,
		);
	}
}

class EquipoStorageService {
	EquipoStorageService(this._api);

	final ApiClient _api;

	Future<Map<String, dynamic>> subirDocumento({
		required String sucursalId,
		required String equipoId,
		required List<int> bytes,
		required String fileName,
		required String contentType,
		String kind = 'planos',
	}) async {
		final presign = await _api.postJson('storage/presign', {
			'sucursalId': sucursalId,
			'entityType': 'equipo',
			'entityId': equipoId,
			'fileName': fileName,
			'contentType': contentType,
			'kind': kind,
		});

		final uploadUrl = presign['uploadUrl'] as String;
		await _api.uploadBytes(uploadUrl, bytes, contentType: contentType);

		return presign;
	}
}
