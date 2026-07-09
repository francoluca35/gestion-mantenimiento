import { IsBoolean, IsDateString, IsEnum, IsOptional } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import { PrioridadOt, TipoMantenimiento } from '@prisma/client';

export class EmitirOtDesdeSolicitudDto {
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
	@IsBoolean()
	notificarAsignacion?: boolean;
}
