import { IsInt, IsOptional, IsString, IsUUID, Min, MinLength } from 'class-validator';

export class CreateUbicacionDto {
	@IsOptional()
	@IsUUID()
	sucursalId?: string;

	@IsOptional()
	@IsUUID()
	parentId?: string;

	@IsString()
	@MinLength(2)
	nombre!: string;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
