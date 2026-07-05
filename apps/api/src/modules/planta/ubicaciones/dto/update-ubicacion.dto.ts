import { IsBoolean, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class UpdateUbicacionDto {
	@IsOptional()
	@IsString()
	@MinLength(2)
	nombre?: string;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;

	@IsOptional()
	@IsBoolean()
	activa?: boolean;
}
