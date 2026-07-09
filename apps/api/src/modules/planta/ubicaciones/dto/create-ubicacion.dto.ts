import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class CreateUbicacionDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsOptional()
	@IsAppUuid()
	parentId?: string;

	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
