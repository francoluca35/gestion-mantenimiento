import { IsIn, IsOptional, IsString, Matches } from 'class-validator';
import { IsAppUuid } from '../../../common/decorators/is-app-uuid.decorator';

export class PresignUploadDto {
	@IsAppUuid()
	sucursalId!: string;

	@IsIn(['ot', 'equipo', 'documento', 'backup'])
	entityType!: 'ot' | 'equipo' | 'documento' | 'backup';

	@IsAppUuid()
	entityId!: string;

	@IsString()
	@Matches(/^[\w.\- ]+\.(jpg|jpeg|png|pdf|webp|mp4)$/i)
	fileName!: string;

	@IsString()
	@Matches(/^(image\/(jpeg|png|webp)|application\/pdf|video\/mp4)$/)
	contentType!: string;

	@IsOptional()
	@IsIn(['fotos', 'firmas', 'pdf', 'planos', 'otros'])
	kind?: 'fotos' | 'firmas' | 'pdf' | 'planos' | 'otros';
}
