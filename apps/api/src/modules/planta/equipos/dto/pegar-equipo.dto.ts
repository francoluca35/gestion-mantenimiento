import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class PegarEquipoDto {
	@IsAppUuid()
	sourceEquipoId!: string;
}
