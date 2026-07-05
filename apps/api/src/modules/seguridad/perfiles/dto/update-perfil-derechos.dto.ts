import { Type } from 'class-transformer';
import {
	ArrayMinSize,
	IsArray,
	IsBoolean,
	IsUUID,
	ValidateNested,
} from 'class-validator';

class PerfilDerechoItemDto {
	@IsUUID()
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
