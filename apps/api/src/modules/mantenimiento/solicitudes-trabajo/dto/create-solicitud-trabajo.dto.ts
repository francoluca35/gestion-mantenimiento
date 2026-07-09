import {
	IsBoolean,
	IsNotEmpty,
	IsOptional,
	IsString,
	MaxLength,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class CreateSolicitudTrabajoDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsString()
	@IsNotEmpty()
	@MaxLength(200)
	solicitante!: string;

	@IsString()
	@IsNotEmpty()
	descripcion!: string;

	@IsOptional()
	@IsBoolean()
	urgente?: boolean;
}
