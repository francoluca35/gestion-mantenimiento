import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class MoverEquipoDto {
	@IsAppUuid()
	ubicacionId!: string;
}
