import { Type } from 'class-transformer';
import {
	IsEnum,
	IsInt,
	IsNotEmpty,
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

export class CreateProcedimientoDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsOptional()
	@IsAppUuid()
	sectorResponsableId?: string;

	@IsOptional()
	@IsString()
	@MaxLength(200)
	nombre?: string;

	@IsEnum(TipoMantenimiento)
	tipo!: TipoMantenimiento;

	@IsString()
	@IsNotEmpty()
	descripcion!: string;

	@IsOptional()
	planillaLecturas?: unknown[];

	@IsOptional()
	@IsString()
	observaciones?: string;

	@ValidateIf((dto: CreateProcedimientoDto) => dto.tipo === 'preventivo')
	@IsEnum(PeriodicidadTipo)
	periodicidadTipo?: PeriodicidadTipo;

	@ValidateIf((dto: CreateProcedimientoDto) => dto.tipo === 'preventivo')
	@IsInt()
	@Min(1)
	periodicidadValor?: number;

	@ValidateIf((dto: CreateProcedimientoDto) => dto.tipo === 'preventivo')
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
}
