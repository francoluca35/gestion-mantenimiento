import { IsIn, IsInt, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateEquipoDocumentoDto {
	@IsString()
	@MinLength(1)
	nombre!: string;

	@IsString()
	@MinLength(1)
	storageKey!: string;

	@IsOptional()
	@IsIn(['plano', 'video', 'pdf', 'otro'])
	tipo?: 'plano' | 'video' | 'pdf' | 'otro';

	@IsOptional()
	@IsString()
	contentType?: string;

	@IsOptional()
	@IsInt()
	tamano?: number;
}
