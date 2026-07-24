import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import type { AuthUser } from '../seguridad/auth/auth.types';
import {
	assertSucursalAccess,
	resolveSucursalId,
} from '../planta/planta.scope';
import {
	CambiarEstadoOcDto,
	CreateOrdenCompraDto,
	CreateProveedorDto,
	UpdateProveedorDto,
} from './dto/compras.dto';

@Injectable()
export class ComprasService {
	constructor(private readonly prisma: PrismaService) {}

	async listProveedores(user: AuthUser, sucursalIdQuery?: string, q?: string) {
		const sucursalId = resolveSucursalId(user, sucursalIdQuery);
		return this.prisma.proveedor.findMany({
			where: {
				sucursalId,
				activo: true,
				...(q?.trim()
					? {
							OR: [
								{ nombre: { contains: q.trim(), mode: 'insensitive' } },
								{ cuit: { contains: q.trim(), mode: 'insensitive' } },
							],
						}
					: {}),
			},
			orderBy: { nombre: 'asc' },
		});
	}

	async createProveedor(user: AuthUser, dto: CreateProveedorDto) {
		const sucursalId = resolveSucursalId(user, dto.sucursalId);
		return this.prisma.proveedor.create({
			data: {
				sucursalId,
				nombre: dto.nombre.trim(),
				cuit: dto.cuit?.trim() || null,
				contacto: dto.contacto?.trim() || null,
				telefono: dto.telefono?.trim() || null,
				email: dto.email?.trim() || null,
			},
		});
	}

	async updateProveedor(user: AuthUser, id: string, dto: UpdateProveedorDto) {
		const existing = await this.prisma.proveedor.findUnique({ where: { id } });
		if (!existing) throw new NotFoundException('Proveedor no encontrado');
		assertSucursalAccess(user, existing.sucursalId);
		return this.prisma.proveedor.update({
			where: { id },
			data: {
				...(dto.nombre != null ? { nombre: dto.nombre.trim() } : {}),
				...(dto.cuit !== undefined ? { cuit: dto.cuit?.trim() || null } : {}),
				...(dto.contacto !== undefined
					? { contacto: dto.contacto?.trim() || null }
					: {}),
				...(dto.telefono !== undefined
					? { telefono: dto.telefono?.trim() || null }
					: {}),
				...(dto.email !== undefined ? { email: dto.email?.trim() || null } : {}),
				...(dto.activo !== undefined ? { activo: dto.activo } : {}),
			},
		});
	}

	async listOrdenes(
		user: AuthUser,
		opts: { sucursalId?: string; estado?: string },
	) {
		const sucursalId = resolveSucursalId(user, opts.sucursalId);
		return this.prisma.ordenCompra.findMany({
			where: {
				sucursalId,
				...(opts.estado ? { estado: opts.estado as never } : {}),
			},
			include: {
				proveedor: { select: { id: true, nombre: true, cuit: true } },
				detalles: {
					include: {
						material: { select: { id: true, codigo: true, nombre: true } },
					},
				},
				creadoPor: { select: { id: true, nombreUsuario: true } },
				autorizadoPor: { select: { id: true, nombreUsuario: true } },
			},
			orderBy: [{ fechaSolicitud: 'desc' }, { numero: 'desc' }],
			take: 200,
		});
	}

	async createOrden(user: AuthUser, dto: CreateOrdenCompraDto) {
		const sucursalId = resolveSucursalId(user, dto.sucursalId);
		const proveedor = await this.prisma.proveedor.findUnique({
			where: { id: dto.proveedorId },
		});
		if (!proveedor || !proveedor.activo) {
			throw new NotFoundException('Proveedor no encontrado');
		}
		assertSucursalAccess(user, proveedor.sucursalId);
		if (proveedor.sucursalId !== sucursalId) {
			throw new BadRequestException('Proveedor de otra sucursal');
		}

		const materialIds = dto.lineas.map((l) => l.materialId);
		const materiales = await this.prisma.material.findMany({
			where: { id: { in: materialIds }, activo: true },
		});
		if (materiales.length !== new Set(materialIds).size) {
			throw new BadRequestException('Hay materiales inválidos en la OC');
		}

		const montoTotal = dto.lineas.reduce(
			(acc, l) => acc + Number(l.cantidad) * Number(l.precioUnitario),
			0,
		);

		const last = await this.prisma.ordenCompra.findFirst({
			where: { sucursalId },
			orderBy: { numero: 'desc' },
			select: { numero: true },
		});
		const numero = (last?.numero ?? 0) + 1;

		return this.prisma.ordenCompra.create({
			data: {
				numero,
				sucursalId,
				proveedorId: dto.proveedorId,
				montoTotal: new Prisma.Decimal(montoTotal.toFixed(2)),
				creadoPorId: user.id,
				notas: dto.notas?.trim() || null,
				detalles: {
					create: dto.lineas.map((l) => ({
						materialId: l.materialId,
						cantidad: new Prisma.Decimal(l.cantidad),
						precioUnitario: new Prisma.Decimal(l.precioUnitario),
					})),
				},
			},
			include: {
				proveedor: true,
				detalles: { include: { material: true } },
			},
		});
	}

	async cambiarEstado(user: AuthUser, id: string, dto: CambiarEstadoOcDto) {
		const oc = await this.prisma.ordenCompra.findUnique({ where: { id } });
		if (!oc) throw new NotFoundException('OC no encontrada');
		assertSucursalAccess(user, oc.sucursalId);

		const next = dto.estado;
		const allowedFrom: Record<string, string[]> = {
			solicitada: ['autorizada', 'no_autorizada', 'anulada'],
			autorizada: ['recibida', 'anulada'],
			no_autorizada: ['anulada'],
			recibida: [],
			anulada: [],
		};
		if (!(allowedFrom[oc.estado] ?? []).includes(next)) {
			throw new BadRequestException(
				`No se puede pasar de ${oc.estado} a ${next}`,
			);
		}

		return this.prisma.ordenCompra.update({
			where: { id },
			data: {
				estado: next,
				...(dto.notas != null ? { notas: dto.notas.trim() || null } : {}),
				...(['autorizada', 'no_autorizada'].includes(next)
					? {
							autorizadoPorId: user.id,
							fechaAutorizacion: new Date(),
						}
					: {}),
			},
			include: {
				proveedor: true,
				detalles: { include: { material: true } },
			},
		});
	}
}
