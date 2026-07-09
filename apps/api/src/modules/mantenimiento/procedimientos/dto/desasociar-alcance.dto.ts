import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class DesasociarAlcanceDto {
	@IsAppUuid()
	alcanceId!: string;
}
