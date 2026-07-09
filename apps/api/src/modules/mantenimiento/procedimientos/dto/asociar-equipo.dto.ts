import { IsBoolean, IsDateString, IsOptional } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class AsociarEquipoDto {
	@IsAppUuid()
	equipoId!: string;

	@IsOptional()
	@IsBoolean()
	emitirPrimeraOt?: boolean;

	@IsOptional()
	@IsDateString()
	fechaProgramacion?: string;

	@IsOptional()
	@IsAppUuid()
	tecnicoAsignadoId?: string;
}
