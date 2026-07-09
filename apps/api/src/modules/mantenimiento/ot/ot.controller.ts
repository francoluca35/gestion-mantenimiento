import {
	Body,
	Controller,
	Get,
	Header,
	Param,
	ParseUUIDPipe,
	Patch,
	Post,
	Query,
	Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { ActualizarEjecucionOtDto } from './dto/actualizar-ejecucion.dto';
import { AnularOtDto } from './dto/anular-ot.dto';
import { AsignarOtDto } from './dto/asignar-ot.dto';
import { CambiarEstadoOtDto } from './dto/cambiar-estado-ot.dto';
import { CompletarChecklistDto } from './dto/completar-checklist.dto';
import { EmitirOtDto } from './dto/emitir-ot.dto';
import { EmitirOtPeriodicaDto } from './dto/emitir-ot-periodica.dto';
import { EmitirOtNecesariasDto } from './dto/emitir-ot-necesarias.dto';
import { RegistrarFirmaDto } from './dto/registrar-firma.dto';
import { ReabrirOtDto } from './dto/reabrir-ot.dto';
import { OtService } from './ot.service';

@Controller('ot')
export class OtController {
	constructor(private readonly otService: OtService) {}

	@Get('necesarias')
	@RequiereDerecho('programacion.ordenes_trabajo.emitir_periodica')
	listarNecesarias(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('necesariasAl') necesariasAl?: string,
		@Query('equipoId') equipoId?: string,
		@Query('sectorResponsableId') sectorResponsableId?: string,
		@Query('tipoProcedimiento') tipoProcedimiento?: string,
		@Query('tipoEquipoId') tipoEquipoId?: string,
	) {
		return this.otService.listarNecesarias(user, {
			sucursalId,
			necesariasAl,
			equipoId,
			sectorResponsableId,
			tipoProcedimiento,
			tipoEquipoId,
		});
	}

	@Post('necesarias/emitir')
	@RequiereDerecho('programacion.ordenes_trabajo.emitir_periodica')
	emitirNecesarias(
		@Body() dto: EmitirOtNecesariasDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.emitirNecesarias(dto, user);
	}

	@Get('tecnicos')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	getTecnicos(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.otService.getTecnicosDisponibles(user, sucursalId);
	}

	@Get('resumen')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	getResumen(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('fechaDesde') fechaDesde?: string,
		@Query('fechaHasta') fechaHasta?: string,
	) {
		return this.otService.getResumen(user, sucursalId, fechaDesde, fechaHasta);
	}

	@Get()
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	findAll(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('estado') estado?: string,
		@Query('tecnicoId') tecnicoId?: string,
		@Query('equipoId') equipoId?: string,
		@Query('ubicacionId') ubicacionId?: string,
		@Query('tipo') tipo?: string,
		@Query('fechaDesde') fechaDesde?: string,
		@Query('fechaHasta') fechaHasta?: string,
		@Query('misOt') misOt?: string,
	) {
		return this.otService.findAll(user, {
			sucursalId,
			estado,
			tecnicoId,
			equipoId,
			ubicacionId,
			tipo,
			fechaDesde,
			fechaHasta,
			misOt: misOt === 'true',
		});
	}

	@Get(':id/pdf/view')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	@Header('Content-Type', 'text/html; charset=utf-8')
	async viewPdf(
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
		@Res() res: Response,
	) {
		const { html } = await this.otService.getPdfHtml(id, user);
		res.send(html);
	}

	@Get(':id/pdf')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	getPdf(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.otService.getPdfHtml(id, user);
	}

	@Get(':id')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.otService.findOne(id, user);
	}

	@Post('emitir')
	@RequiereDerecho('programacion.ordenes_trabajo.emitir_no_periodica')
	emitir(@Body() dto: EmitirOtDto, @CurrentUser() user: AuthUser) {
		return this.otService.emitir(dto, user);
	}

	@Post('emitir-periodica')
	@RequiereDerecho('programacion.ordenes_trabajo.emitir_periodica')
	emitirPeriodica(
		@Body() dto: EmitirOtPeriodicaDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.emitirPeriodica(dto, user);
	}

	@Patch(':id/asignar')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	asignar(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AsignarOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.asignar(id, dto, user);
	}

	@Patch(':id/estado')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	cambiarEstado(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: CambiarEstadoOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.cambiarEstado(id, dto, user);
	}

	@Patch(':id/ejecucion')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	actualizarEjecucion(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: ActualizarEjecucionOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.actualizarEjecucion(id, dto, user);
	}

	@Post(':id/checklist')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	completarChecklist(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: CompletarChecklistDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.completarChecklist(id, dto, user);
	}

	@Post(':id/firma')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	registrarFirma(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: RegistrarFirmaDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.registrarFirma(id, dto, user);
	}

	@Post(':id/anular')
	@RequiereDerecho('programacion.ordenes_trabajo.anular')
	anular(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AnularOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.anular(id, dto, user);
	}

	@Post(':id/reabrir')
	@RequiereDerecho('programacion.ordenes_trabajo.reabrir')
	reabrir(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: ReabrirOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.reabrir(id, dto, user);
	}
}
