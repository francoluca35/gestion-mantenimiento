import { Type } from 'class-transformer';
import {
	ArrayMinSize,
	IsBoolean,
	IsDateString,
	IsEnum,
	IsOptional,
	ValidateNested,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import { PrioridadOt } from '@prisma/client';

export class EmitirOtNecesariaItemDto {
	@IsAppUuid()
	procedimientoId!: string;

	@IsAppUuid()
	equipoId!: string;

	@IsDateString()
	fechaProgramacion!: string;

	@IsOptional()
	@IsAppUuid()
	tecnicoAsignadoId?: string;

	@IsOptional()
	@IsEnum(PrioridadOt)
	prioridad?: PrioridadOt;

	@IsOptional()
	@IsBoolean()
	notificarAsignacion?: boolean;
}

export class EmitirOtNecesariasDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@ValidateNested({ each: true })
	@Type(() => EmitirOtNecesariaItemDto)
	@ArrayMinSize(1)
	items!: EmitirOtNecesariaItemDto[];
}
