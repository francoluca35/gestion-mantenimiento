import { Type } from 'class-transformer';
import {
	IsArray,
	IsOptional,
	IsString,
	MaxLength,
	ValidateNested,
} from 'class-validator';

export class OtFotoDto {
	@IsString()
	key!: string;

	@IsString()
	url!: string;

	@IsOptional()
	@IsString()
	nombre?: string;

	@IsOptional()
	@IsString()
	contentType?: string;
}

export class ActualizarEjecucionOtDto {
	@IsOptional()
	@IsString()
	@MaxLength(5000)
	novedadesFueraDePrograma?: string;

	@IsOptional()
	@IsString()
	@MaxLength(5000)
	comentarios?: string;

	@IsOptional()
	@IsArray()
	@ValidateNested({ each: true })
	@Type(() => OtFotoDto)
	fotos?: OtFotoDto[];

	@IsOptional()
	@IsArray()
	items?: unknown[];
}
