import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import type { AuthUser } from '../seguridad/auth/auth.types';
import { resolveSucursalId } from '../planta/planta.scope';

@Injectable()
export class IndicadoresService {
	constructor(private readonly prisma: PrismaService) {}

	async dashboard(user: AuthUser, sucursalIdQuery?: string) {
		const sucursalId = resolveSucursalId(user, sucursalIdQuery);
		const hoy = new Date();
		hoy.setHours(0, 0, 0, 0);
		const finDia = new Date(hoy);
		finDia.setHours(23, 59, 59, 999);

		const inicioSemana = new Date(hoy);
		const day = inicioSemana.getDay();
		inicioSemana.setDate(inicioSemana.getDate() + (day === 0 ? -6 : 1 - day));
		inicioSemana.setHours(0, 0, 0, 0);

		const inicioMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
		const inicioAnio = new Date(hoy.getFullYear(), 0, 1);
		const hace30 = new Date(hoy);
		hace30.setDate(hace30.getDate() - 29);

		const base = { sucursalId, estado: { not: 'anulada' as const } };

		const [
			otSemana,
			otMes,
			otAnio,
			pendientes,
			enEjecucion,
			pendientePanol,
			realizadasMes,
			atrasadas,
			solicitudesPendientes,
			pedidosMaterialesPendientes,
			ocSolicitadas,
			porTecnicoRaw,
			porEstadoRaw,
		] = await Promise.all([
			this.prisma.ordenTrabajo.count({
				where: {
					...base,
					fechaProgramacion: { gte: inicioSemana, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					...base,
					fechaProgramacion: { gte: inicioMes, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					...base,
					fechaProgramacion: { gte: inicioAnio, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: { sucursalId, estado: 'pendiente' },
			}),
			this.prisma.ordenTrabajo.count({
				where: { sucursalId, estado: 'en_ejecucion' },
			}),
			this.prisma.ordenTrabajo.count({
				where: { sucursalId, estado: 'pendiente_panol' },
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					sucursalId,
					estado: 'realizada',
					fechaProgramacion: { gte: inicioMes, lte: finDia },
				},
			}),
			this.prisma.ordenTrabajo.count({
				where: {
					sucursalId,
					estado: { in: ['pendiente', 'en_ejecucion', 'pendiente_panol'] },
					fechaProgramacion: { lt: hoy },
				},
			}),
			this.prisma.solicitudTrabajo.count({
				where: { sucursalId, estado: 'pendiente' },
			}),
			this.prisma.pedidoStock.count({
				where: {
					estado: { in: ['pendiente', 'en_proceso'] },
					panol: { sucursalId },
				},
			}),
			this.prisma.ordenCompra.count({
				where: { sucursalId, estado: 'solicitada' },
			}),
			this.prisma.ordenTrabajo.groupBy({
				by: ['tecnicoAsignadoId'],
				where: {
					sucursalId,
					estado: { in: ['pendiente', 'en_ejecucion', 'pendiente_panol'] },
					tecnicoAsignadoId: { not: null },
				},
				_count: { _all: true },
			}),
			this.prisma.ordenTrabajo.groupBy({
				by: ['estado'],
				where: { sucursalId, estado: { not: 'anulada' } },
				_count: { _all: true },
			}),
		]);

		const tecnicoIds = porTecnicoRaw
			.map((r) => r.tecnicoAsignadoId)
			.filter((id): id is string => !!id);
		const tecnicos = tecnicoIds.length
			? await this.prisma.usuario.findMany({
					where: { id: { in: tecnicoIds } },
					select: { id: true, nombreUsuario: true },
				})
			: [];
		const tecnicoMap = Object.fromEntries(
			tecnicos.map((t) => [t.id, t.nombreUsuario]),
		);

		const totalMes = otMes || 1;
		const cumplimientoMes = Math.round((realizadasMes / totalMes) * 100);

		return {
			periodos: { semana: otSemana, mes: otMes, anio: otAnio },
			estado: {
				pendientes,
				enEjecucion,
				pendientePanol,
				realizadasMes,
				atrasadas,
			},
			cumplimientoMes,
			bandejas: {
				solicitudesTrabajo: solicitudesPendientes,
				pedidosMateriales: pedidosMaterialesPendientes,
				ocPendientesAutorizacion: ocSolicitadas,
			},
			porTecnico: porTecnicoRaw
				.map((r) => ({
					tecnicoId: r.tecnicoAsignadoId,
					nombre: r.tecnicoAsignadoId
						? (tecnicoMap[r.tecnicoAsignadoId] ?? '—')
						: 'Sin asignar',
					abiertas: r._count._all,
				}))
				.sort((a, b) => b.abiertas - a.abiertas)
				.slice(0, 12),
			porEstado: porEstadoRaw.map((r) => ({
				estado: r.estado,
				cantidad: r._count._all,
			})),
		};
	}
}
