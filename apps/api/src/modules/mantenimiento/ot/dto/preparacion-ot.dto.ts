import { Type } from 'class-transformer';
import {
	IsBoolean,
	IsNumber,
	IsOptional,
	IsString,
	IsUUID,
	Min,
	MinLength,
} from 'class-validator';

export class RegistrarLecturaOtDto {
	@IsString()
	@MinLength(1)
	tipo!: string;

	@Type(() => Number)
	@IsNumber()
	valor!: number;

	@IsOptional()
	@IsString()
	notas?: string;
}

export class AnalizarMaterialesOtDto {
	@IsString()
	@MinLength(2)
	texto!: string;

	@IsOptional()
	@IsUUID()
	panolId?: string;
}

export class ConfirmarMaterialesOtDto {
	@IsString()
	@MinLength(2)
	texto!: string;

	@IsOptional()
	@IsUUID()
	panolId?: string;

	/** Si hay faltantes, igual crea solicitudes/pedidos y habilita continuar. */
	@IsOptional()
	@IsBoolean()
	procederConFaltantes?: boolean;
}

export class DecidirSinMaterialesOtDto {
	@IsOptional()
	@IsString()
	comentario?: string;
}
