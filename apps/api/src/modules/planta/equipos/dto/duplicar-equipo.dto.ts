import { IsOptional } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class DuplicarEquipoDto {
	@IsOptional()
	@IsAppUuid()
	ubicacionId?: string;
}
