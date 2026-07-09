import '../../../core/network/api_client.dart';

class OtFoto {
	const OtFoto({
		required this.key,
		required this.url,
		this.nombre,
		this.contentType,
		this.subidoEn,
	});

	final String key;
	final String url;
	final String? nombre;
	final String? contentType;
	final String? subidoEn;

	Map<String, dynamic> toJson() => {
			'key': key,
			'url': url,
			if (nombre != null) 'nombre': nombre,
			if (contentType != null) 'contentType': contentType,
			if (subidoEn != null) 'subidoEn': subidoEn,
		};

	factory OtFoto.fromJson(Map<String, dynamic> json) => OtFoto(
			key: json['key'] as String,
			url: json['url'] as String,
			nombre: json['nombre'] as String?,
			contentType: json['contentType'] as String?,
			subidoEn: json['subidoEn'] as String?,
		);
}

class OtStorageService {
	OtStorageService(this._api);

	final ApiClient _api;

	Future<OtFoto> subirFotoOt({
		required String sucursalId,
		required String otId,
		required List<int> bytes,
		required String fileName,
		required String contentType,
	}) async {
		final presign = await _api.postJson('storage/presign', {
			'sucursalId': sucursalId,
			'entityType': 'ot',
			'entityId': otId,
			'fileName': fileName,
			'contentType': contentType,
			'kind': 'fotos',
		});

		final uploadUrl = presign['uploadUrl'] as String;
		await _api.uploadBytes(uploadUrl, bytes, contentType: contentType);

		return OtFoto(
			key: presign['key'] as String,
			url: presign['publicUrl'] as String,
			nombre: fileName,
			contentType: contentType,
			subidoEn: DateTime.now().toIso8601String(),
		);
	}
}
