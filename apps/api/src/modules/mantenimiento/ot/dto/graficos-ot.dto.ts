import {
	IsArray,
	IsBoolean,
	IsDateString,
	IsEnum,
	IsOptional,
	IsString,
	Matches,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
import { TipoMantenimiento } from '@prisma/client';

export enum EjeYGraficos {
	horas_hombre = 'horas_hombre',
	costos = 'costos',
	indisponibilidad = 'indisponibilidad',
	cantidad_ot = 'cantidad_ot',
}

export enum EjeXGraficos {
	mes = 'mes',
	responsable = 'responsable',
	tipo_trabajo = 'tipo_trabajo',
	equipos = 'equipos',
}

export enum AgrupadoGraficos {
	mes = 'mes',
	responsable = 'responsable',
	tipo_trabajo = 'tipo_trabajo',
	ninguno = 'ninguno',
}

export enum TipoGraficoOt {
	barras_3d = 'barras_3d',
	linea_3d = 'linea_3d',
	torta_3d = 'torta_3d',
	barras_2d = 'barras_2d',
	linea_2d = 'linea_2d',
	torta_2d = 'torta_2d',
}

export class GraficosOtDto {
	@IsOptional()
	@IsAppUuid()
	sucursalId?: string;

	@IsDateString()
	fechaDesde!: string;

	@IsDateString()
	fechaHasta!: string;

	@IsEnum(EjeYGraficos)
	ejeY!: EjeYGraficos;

	@IsEnum(EjeXGraficos)
	ejeX!: EjeXGraficos;

	@IsEnum(AgrupadoGraficos)
	agrupado!: AgrupadoGraficos;

	@IsEnum(TipoGraficoOt)
	tipoGrafico!: TipoGraficoOt;

	@IsOptional()
	@IsBoolean()
	plantaCompleta?: boolean;

	@IsOptional()
	@IsArray()
	@Matches(
		/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
		{ each: true },
	)
	equipoIds?: string[];

	@IsOptional()
	@IsAppUuid()
	sectorResponsableId?: string;

	@IsOptional()
	@IsEnum(TipoMantenimiento)
	tipoProcedimiento?: TipoMantenimiento;

	@IsOptional()
	@IsAppUuid()
	tipoEquipoId?: string;

	@IsOptional()
	@IsString()
	ubicacionId?: string;
}
