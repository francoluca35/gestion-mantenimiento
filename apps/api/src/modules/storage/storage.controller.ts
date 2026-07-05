import {
	Body,
	Controller,
	Get,
	Param,
	Post,
	Req,
	Res,
	StreamableFile,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { Public } from '../../common/decorators/public.decorator';
import { PresignUploadDto } from './dto/presign-upload.dto';
import { StorageService } from './storage.service';

@Controller('storage')
export class StorageController {
	constructor(private readonly storageService: StorageService) {}

	@Public()
	@Get('status')
	getStatus() {
		return {
			provider: this.storageService.getProvider(),
			ready: true,
		};
	}

	@Post('presign')
	presign(@Body() dto: PresignUploadDto) {
		return this.storageService.createPresignedUpload(dto);
	}

	@Post('upload/:key')
	async uploadLocal(
		@Param('key') key: string,
		@Req() req: Request,
	) {
		const decodedKey = decodeURIComponent(key);
		const meta = await this.storageService.saveLocalFile(decodedKey, req);
		return meta;
	}

	@Get('files/:key')
	downloadLocal(
		@Param('key') key: string,
		@Res({ passthrough: true }) res: Response,
	) {
		const decodedKey = decodeURIComponent(key);
		const stream = this.storageService.getLocalReadStream(decodedKey);
		res.set({
			'Content-Disposition': `inline; filename="${decodedKey.split('/').pop()}"`,
		});
		return new StreamableFile(stream);
	}
}
