import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class UpdateMotivoOtPendienteDto {
	@IsOptional()
	@IsString()
	@MaxLength(30)
	codigo?: string;

	@IsOptional()
	@IsString()
	@MaxLength(200)
	descripcion?: string;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
