import { IsObject, IsOptional, IsString, MinLength } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class CreateEquipoDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsAppUuid()
	ubicacionId!: string;

	@IsAppUuid()
	tipoEquipoId!: string;

	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsString()
	@MinLength(1)
	codigo!: string;

	@IsOptional()
	@IsObject()
	detalle?: Record<string, unknown>;
}
