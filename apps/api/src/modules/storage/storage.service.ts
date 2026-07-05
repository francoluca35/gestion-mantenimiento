import {
	DeleteObjectCommand,
	GetObjectCommand,
	PutObjectCommand,
	S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createReadStream, createWriteStream, existsSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { pipeline } from 'stream/promises';
import {
	PresignUploadInput,
	PresignUploadResult,
	StorageObjectMeta,
	StorageProvider,
} from './storage.types';

@Injectable()
export class StorageService {
	private readonly logger = new Logger(StorageService.name);
	private readonly provider: StorageProvider;
	private readonly bucket: string;
	private readonly publicUrl: string;
	private readonly localRoot: string;
	private readonly s3Client: S3Client | null;

	constructor(private readonly config: ConfigService) {
		this.provider = this.config.get<StorageProvider>('STORAGE_PROVIDER', 'minio');
		this.bucket = this.config.get<string>('STORAGE_BUCKET', 'sika-mantenimiento');
		this.publicUrl = this.config.get<string>(
			'STORAGE_PUBLIC_URL',
			`http://localhost:9000/${this.bucket}`,
		);
		this.localRoot = this.config.get<string>(
			'STORAGE_LOCAL_ROOT',
			join(process.cwd(), 'storage'),
		);

		if (this.provider === 'local') {
			this.s3Client = null;
			if (!existsSync(this.localRoot)) {
				mkdirSync(this.localRoot, { recursive: true });
			}
			this.logger.log(`Storage local en ${this.localRoot}`);
			return;
		}

		const endpoint = this.config.get<string>('STORAGE_ENDPOINT');
		const forcePathStyle = this.config.get<string>('STORAGE_FORCE_PATH_STYLE', 'true') === 'true';

		this.s3Client = new S3Client({
			region: this.config.get<string>('STORAGE_REGION', 'us-east-1'),
			endpoint: endpoint || undefined,
			forcePathStyle,
			credentials: {
				accessKeyId: this.config.get<string>('STORAGE_ACCESS_KEY', 'minioadmin'),
				secretAccessKey: this.config.get<string>('STORAGE_SECRET_KEY', 'minioadmin'),
			},
		});

		this.logger.log(`Storage provider: ${this.provider} (bucket: ${this.bucket})`);
	}

	buildObjectKey(input: PresignUploadInput): string {
		const kind = input.kind ?? 'otros';
		const safeName = input.fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
		const stamp = Date.now();

		return [
			input.sucursalId,
			input.entityType,
			input.entityId,
			kind,
			`${stamp}-${safeName}`,
		].join('/');
	}

	async createPresignedUpload(
		input: PresignUploadInput,
		expiresInSeconds = 900,
	): Promise<PresignUploadResult> {
		const key = this.buildObjectKey(input);

		if (this.provider === 'local') {
			return {
				key,
				uploadUrl: `/v1/storage/upload/${encodeURIComponent(key)}`,
				publicUrl: this.getPublicUrl(key),
				expiresInSeconds,
			};
		}

		const command = new PutObjectCommand({
			Bucket: this.bucket,
			Key: key,
			ContentType: input.contentType,
		});

		const uploadUrl = await getSignedUrl(this.s3Client!, command, {
			expiresIn: expiresInSeconds,
		});

		return {
			key,
			uploadUrl,
			publicUrl: this.getPublicUrl(key),
			expiresInSeconds,
		};
	}

	async createPresignedDownload(key: string, expiresInSeconds = 900): Promise<string> {
		if (this.provider === 'local') {
			return this.getPublicUrl(key);
		}

		const command = new GetObjectCommand({
			Bucket: this.bucket,
			Key: key,
		});

		return getSignedUrl(this.s3Client!, command, { expiresIn: expiresInSeconds });
	}

	async saveLocalFile(key: string, stream: NodeJS.ReadableStream): Promise<StorageObjectMeta> {
		const fullPath = join(this.localRoot, key);
		mkdirSync(dirname(fullPath), { recursive: true });
		await pipeline(stream, createWriteStream(fullPath));

		return {
			key,
			publicUrl: this.getPublicUrl(key),
		};
	}

	getLocalReadStream(key: string) {
		return createReadStream(join(this.localRoot, key));
	}

	async deleteObject(key: string): Promise<void> {
		if (this.provider === 'local') {
			const { unlink } = await import('fs/promises');
			const fullPath = join(this.localRoot, key);
			if (existsSync(fullPath)) {
				await unlink(fullPath);
			}
			return;
		}

		await this.s3Client!.send(
			new DeleteObjectCommand({
				Bucket: this.bucket,
				Key: key,
			}),
		);
	}

	getPublicUrl(key: string): string {
		if (this.provider === 'local') {
			return `/v1/storage/files/${encodeURIComponent(key)}`;
		}

		return `${this.publicUrl.replace(/\/$/, '')}/${key}`;
	}

	getProvider(): StorageProvider {
		return this.provider;
	}
}
