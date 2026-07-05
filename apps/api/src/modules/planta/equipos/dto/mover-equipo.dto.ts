import { IsUUID } from 'class-validator';

export class MoverEquipoDto {
	@IsUUID()
	ubicacionId!: string;
}
