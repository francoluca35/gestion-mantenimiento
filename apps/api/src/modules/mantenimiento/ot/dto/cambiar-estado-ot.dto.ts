import { IsEnum, IsOptional, IsString } from 'class-validator';
import { EstadoOt } from '@prisma/client';

export class CambiarEstadoOtDto {
	@IsEnum(EstadoOt)
	estado!: EstadoOt;

	@IsOptional()
	@IsString()
	comentario?: string;
}
