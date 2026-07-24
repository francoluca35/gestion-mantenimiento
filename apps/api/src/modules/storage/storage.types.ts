export type StorageProvider = 'minio' | 'r2' | 's3' | 'local';

export type StorageEntityType = 'ot' | 'equipo' | 'documento' | 'backup' | 'sucursal';

export interface PresignUploadInput {
	sucursalId: string;
	entityType: StorageEntityType;
	entityId: string;
	fileName: string;
	contentType: string;
	kind?: 'fotos' | 'firmas' | 'pdf' | 'planos' | 'otros' | 'logos';
}

export interface PresignUploadResult {
	key: string;
	uploadUrl: string;
	publicUrl: string;
	expiresInSeconds: number;
}

export interface StorageObjectMeta {
	key: string;
	publicUrl: string;
}
