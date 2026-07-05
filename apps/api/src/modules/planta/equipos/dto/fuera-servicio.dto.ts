import { IsBoolean } from 'class-validator';

export class FueraServicioDto {
	@IsBoolean()
	fuera!: boolean;
}
