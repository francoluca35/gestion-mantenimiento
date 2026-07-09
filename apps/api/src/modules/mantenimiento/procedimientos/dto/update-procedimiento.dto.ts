import { Type } from 'class-transformer';
import {
	IsBoolean,
	IsEnum,
	IsInt,
	IsNumber,
	IsOptional,
	IsString,
	MaxLength,
	Min,
	ValidateIf,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import {
	CriterioProgramacion,
	PeriodicidadTipo,
	TipoMantenimiento,
} from '@prisma/client';

export class UpdateProcedimientoDto {
	@IsOptional()
	@IsAppUuid()
	sectorResponsableId?: string;

	@IsOptional()
	@IsString()
	@MaxLength(200)
	nombre?: string;

	@IsOptional()
	@IsEnum(TipoMantenimiento)
	tipo?: TipoMantenimiento;

	@IsOptional()
	@IsString()
	descripcion?: string;

	@IsOptional()
	planillaLecturas?: unknown[];

	@IsOptional()
	@IsString()
	observaciones?: string;

	@IsOptional()
	@IsEnum(PeriodicidadTipo)
	periodicidadTipo?: PeriodicidadTipo;

	@IsOptional()
	@IsInt()
	@Min(1)
	periodicidadValor?: number;

	@IsOptional()
	@IsEnum(CriterioProgramacion)
	criterioProgramacion?: CriterioProgramacion;

	@IsOptional()
	@IsInt()
	@Min(0)
	tolerancia?: number;

	@IsOptional()
	@IsInt()
	@Min(1)
	duracionEstimada?: number;

	@IsOptional()
	@Type(() => Number)
	@IsNumber()
	@Min(0)
	hsHombre?: number;

	@IsOptional()
	@IsInt()
	@Min(1)
	cantOperarios?: number;

	@IsOptional()
	@IsInt()
	@Min(0)
	indisponibilidadEstimada?: number;

	@IsOptional()
	@Type(() => Number)
	@IsNumber()
	@Min(0)
	costoEstimado?: number;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
