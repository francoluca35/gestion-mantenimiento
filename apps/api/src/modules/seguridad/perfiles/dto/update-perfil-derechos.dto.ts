import { Type } from 'class-transformer';
import {
	ArrayMinSize,
	IsArray,
	IsBoolean,
	ValidateNested,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

class PerfilDerechoItemDto {
	@IsAppUuid()
	derechoId!: string;

	@IsBoolean()
	habilitado!: boolean;

	@IsBoolean()
	modoTotal!: boolean;
}

export class UpdatePerfilDerechosDto {
	@IsArray()
	@ArrayMinSize(0)
	@ValidateNested({ each: true })
	@Type(() => PerfilDerechoItemDto)
	derechos!: PerfilDerechoItemDto[];
}
