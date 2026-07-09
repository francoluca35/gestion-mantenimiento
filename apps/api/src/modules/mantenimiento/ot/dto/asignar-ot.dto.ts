import { IsOptional, IsString } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class AsignarOtDto {
	@IsAppUuid()
	tecnicoAsignadoId!: string;

	@IsOptional()
	@IsString()
	comentario?: string;
}
