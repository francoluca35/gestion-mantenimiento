import { IsIn } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class CambiarEstadoEquipoDto {
	@IsAppUuid()
	equipoId!: string;

	@IsIn(['activo', 'suspendido'])
	estado!: 'activo' | 'suspendido';
}
