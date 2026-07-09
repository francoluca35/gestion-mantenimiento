import { IsIn, IsOptional, IsString } from 'class-validator';
import type { EstadoOt } from '@prisma/client';

export class ReabrirOtDto {
	@IsOptional()
	@IsIn(['pendiente', 'en_ejecucion'])
	estado?: Extract<EstadoOt, 'pendiente' | 'en_ejecucion'>;

	@IsOptional()
	@IsString()
	comentario?: string;
}
