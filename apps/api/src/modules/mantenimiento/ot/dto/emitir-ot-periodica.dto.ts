import {
	IsBoolean,
	IsDateString,
	IsEnum,
	IsOptional,
	IsString,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import { PrioridadOt } from '@prisma/client';

export class EmitirOtPeriodicaDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsAppUuid()
	procedimientoId!: string;

	@IsAppUuid()
	equipoId!: string;

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
