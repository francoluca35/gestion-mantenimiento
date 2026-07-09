import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class DesasociarEquipoDto {
	@IsAppUuid()
	equipoId!: string;
}
