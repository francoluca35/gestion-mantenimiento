import { IsIn, IsOptional, IsString, IsUUID, Matches } from 'class-validator';

export class PresignUploadDto {
	@IsUUID()
	sucursalId!: string;

	@IsIn(['ot', 'equipo', 'documento', 'backup'])
	entityType!: 'ot' | 'equipo' | 'documento' | 'backup';

	@IsUUID()
	entityId!: string;

	@IsString()
	@Matches(/^[\w.\- ]+\.(jpg|jpeg|png|pdf|webp)$/i)
	fileName!: string;

	@IsString()
	@Matches(/^(image\/(jpeg|png|webp)|application\/pdf)$/)
	contentType!: string;

	@IsOptional()
	@IsIn(['fotos', 'firmas', 'pdf', 'planos', 'otros'])
	kind?: 'fotos' | 'firmas' | 'pdf' | 'planos' | 'otros';
}
