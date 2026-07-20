import { Type } from 'class-transformer';
import {
	ArrayMinSize,
	IsArray,
	IsNumber,
	IsOptional,
	IsString,
	IsUUID,
	Min,
	ValidateNested,
} from 'class-validator';

export class SolicitudMaterialItemDto {
	@IsUUID()
	materialId!: string;

	@IsNumber()
	@Min(0.01)
	cantidad!: number;
}

export class CreateSolicitudesMaterialesDto {
	@IsUUID()
	otId!: string;

	@IsOptional()
	@IsUUID()
	panolId?: string;

	@IsArray()
	@ArrayMinSize(1)
	@ValidateNested({ each: true })
	@Type(() => SolicitudMaterialItemDto)
	items!: SolicitudMaterialItemDto[];
}

export class RechazarSolicitudMaterialDto {
	@IsString()
	motivo!: string;
}
