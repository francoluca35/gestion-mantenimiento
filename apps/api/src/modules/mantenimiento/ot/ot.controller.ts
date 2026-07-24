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
import { AsignarMotivoPendienteDto } from './dto/asignar-motivo-pendiente.dto';
import { AsignarOtDto } from './dto/asignar-ot.dto';
import { CambiarEstadoOtDto } from './dto/cambiar-estado-ot.dto';
import { CompletarChecklistDto } from './dto/completar-checklist.dto';
import { DerivarOtDto } from './dto/derivar-ot.dto';
import { EmitirOtDto } from './dto/emitir-ot.dto';
import { EmitirOtPeriodicaDto } from './dto/emitir-ot-periodica.dto';
import { EmitirOtNecesariasDto } from './dto/emitir-ot-necesarias.dto';
import { GraficosOtDto } from './dto/graficos-ot.dto';
import {
	AnalizarMaterialesOtDto,
	ConfirmarMaterialesOtDto,
	DecidirSinMaterialesOtDto,
	RegistrarLecturaOtDto,
} from './dto/preparacion-ot.dto';
import { RegistrarFirmaDto } from './dto/registrar-firma.dto';
import { ReabrirOtDto } from './dto/reabrir-ot.dto';
import { OtPdfBinaryService } from './ot-pdf-binary.service';
import { OtService } from './ot.service';

@Controller('ot')
export class OtController {
	constructor(
		private readonly otService: OtService,
		private readonly pdfBinary: OtPdfBinaryService,
	) {}

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

	@Get('gantt')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	getGantt(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
		@Query('fechaDesde') fechaDesde?: string,
		@Query('fechaHasta') fechaHasta?: string,
		@Query('agruparPor') agruparPor?: 'equipo' | 'sector',
		@Query('ubicacionId') ubicacionId?: string,
		@Query('misOt') misOt?: string,
	) {
		return this.otService.getGantt(user, {
			sucursalId,
			fechaDesde,
			fechaHasta,
			agruparPor,
			ubicacionId,
			misOt: misOt === 'true' || misOt === '1',
		});
	}

	@Post('graficos')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	getGraficos(@CurrentUser() user: AuthUser, @Body() dto: GraficosOtDto) {
		return this.otService.getGraficos(user, dto);
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
		@Query('prioridad') prioridad?: string,
		@Query('numero') numero?: string,
		@Query('sectorResponsableId') sectorResponsableId?: string,
		@Query('motivoPendienteId') motivoPendienteId?: string,
		@Query('tipoEquipoId') tipoEquipoId?: string,
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
			prioridad,
			numero,
			sectorResponsableId,
			motivoPendienteId,
			tipoEquipoId,
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

	@Get(':id/pdf/file')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	async downloadPdf(
		@Param('id', ParseUUIDPipe) id: string,
		@CurrentUser() user: AuthUser,
		@Res() res: Response,
	) {
		const { html, numero } = await this.otService.getPdfHtml(id, user);
		const pdf = await this.pdfBinary.htmlToPdf(html);
		res.setHeader('Content-Type', 'application/pdf');
		res.setHeader(
			'Content-Disposition',
			`attachment; filename="OT-${numero}.pdf"`,
		);
		res.send(pdf);
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

	@Patch(':id/motivo-pendiente')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	asignarMotivoPendiente(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AsignarMotivoPendienteDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.asignarMotivoPendiente(id, dto.motivoPendienteId, user);
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

	@Post(':id/lectura')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	registrarLectura(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: RegistrarLecturaOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.registrarLecturaOt(id, dto, user);
	}

	@Post(':id/materiales/analizar')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	analizarMateriales(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: AnalizarMaterialesOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.analizarMaterialesOt(id, dto, user);
	}

	@Post(':id/materiales/sin-necesidad')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	sinMateriales(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: DecidirSinMaterialesOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.decidirSinMateriales(id, dto, user);
	}

	@Post(':id/materiales/confirmar')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	confirmarMateriales(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: ConfirmarMaterialesOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.confirmarMaterialesOt(id, dto, user);
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

	@Post(':id/derivar')
	@RequiereDerecho('programacion.ordenes_trabajo.emitir_no_periodica')
	derivar(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: DerivarOtDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.otService.derivar(id, dto, user);
	}
}
