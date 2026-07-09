import { IsOptional } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class AsignarMotivoPendienteDto {
	@IsOptional()
	@IsAppUuid()
	motivoPendienteId?: string | null;
}
