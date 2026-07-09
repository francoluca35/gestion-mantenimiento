import {
	IsBoolean,
	IsDateString,
	IsEnum,
	IsNotEmpty,
	IsOptional,
	IsString,
	MaxLength,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import { PrioridadOt, TipoMantenimiento } from '@prisma/client';

export class EmitirOtDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsAppUuid()
	equipoId!: string;

	@IsOptional()
	@IsAppUuid()
	procedimientoId?: string;

	@IsEnum(TipoMantenimiento)
	tipo!: TipoMantenimiento;

	@IsOptional()
	@IsAppUuid()
	tecnicoAsignadoId?: string;

	@IsDateString()
	fechaProgramacion!: string;

	@IsOptional()
	@IsEnum(PrioridadOt)
	prioridad?: PrioridadOt;

	@IsOptional()
	@IsString()
	comentarios?: string;

	@IsOptional()
	@IsBoolean()
	notificarAsignacion?: boolean;
}
