import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

const CALIFICACIONES = ['muy_bueno', 'bueno', 'regular', 'malo'] as const;

export class ConformidadSolicitudDto {
	@IsBoolean()
	conforme!: boolean;

	@IsOptional()
	@IsIn(CALIFICACIONES)
	calificacion?: (typeof CALIFICACIONES)[number];

	@IsOptional()
	@IsString()
	observaciones?: string;
}
