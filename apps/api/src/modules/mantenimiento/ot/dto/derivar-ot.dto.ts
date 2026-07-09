import { IsOptional, IsString, MinLength } from 'class-validator';

export class DerivarOtDto {
	@IsOptional()
	@IsString()
	@MinLength(1)
	comentarios?: string;
}
