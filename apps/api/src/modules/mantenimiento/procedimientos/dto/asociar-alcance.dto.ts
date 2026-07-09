import { IsEnum } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export enum AlcanceAsociacionTipo {
	ubicacion = 'ubicacion',
	planta = 'planta',
}

export class AsociarAlcanceDto {
	@IsEnum(AlcanceAsociacionTipo)
	tipo!: AlcanceAsociacionTipo;

	@IsAppUuid()
	targetId!: string;
}
