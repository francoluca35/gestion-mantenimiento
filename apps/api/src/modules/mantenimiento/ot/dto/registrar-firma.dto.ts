import { IsNotEmpty, IsString } from 'class-validator';

export class RegistrarFirmaDto {
	@IsString()
	@IsNotEmpty()
	firmaDigital!: string;
}
