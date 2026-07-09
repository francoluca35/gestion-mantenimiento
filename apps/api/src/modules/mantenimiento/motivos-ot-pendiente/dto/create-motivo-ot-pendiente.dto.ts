import { IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateMotivoOtPendienteDto {
	@IsString()
	@MaxLength(30)
	codigo!: string;

	@IsString()
	@MaxLength(200)
	descripcion!: string;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
