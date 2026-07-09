import { IsOptional, IsString } from 'class-validator';

export class AnularOtDto {
	@IsOptional()
	@IsString()
	comentario?: string;
}
