import {
	BadRequestException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { AuthUser } from '../../seguridad/auth/auth.types';
import { resolveSucursalId } from '../../planta/planta.scope';
import { CreateMaterialDto, UpdateMaterialDto } from './dto/material.dto';

@Injectable()
export class MaterialesService {
	constructor(private readonly prisma: PrismaService) {}

	async findUnidades() {
		return this.prisma.unidad.findMany({
			where: { activo: true },
			orderBy: { codigo: 'asc' },
		});
	}

	async findAll(q?: string) {
		return this.prisma.material.findMany({
			where: {
				activo: true,
				...(q?.trim()
					? {
							OR: [
								{ nombre: { contains: q.trim(), mode: 'insensitive' } },
								{ codigo: { contains: q.trim(), mode: 'insensitive' } },
							],
						}
					: {}),
			},
			include: { unidad: true },
			orderBy: { nombre: 'asc' },
		});
	}

	async create(dto: CreateMaterialDto, currentUser: AuthUser) {
		if (dto.panolId) {
			const panol = await this.prisma.panol.findUnique({
				where: { id: dto.panolId },
			});
			if (!panol || !panol.activo) {
				throw new NotFoundException('Pañol no encontrado');
			}
			resolveSucursalId(currentUser, panol.sucursalId);
		}

		return this.prisma.$transaction(async (tx) => {
			const material = await tx.material.create({
				data: {
					codigo: dto.codigo.trim().toUpperCase(),
					nombre: dto.nombre.trim(),
					marca: dto.marca?.trim() || null,
					uso: dto.uso?.trim() || 'Mantenimiento',
					unidadId: dto.unidadId,
					precioActual: dto.precioActual ?? 0,
				},
				include: { unidad: true },
			});

			if (dto.panolId) {
				await tx.stockItem.create({
					data: {
						panolId: dto.panolId,
						materialId: material.id,
						cantidadActual: dto.cantidadActual ?? 0,
						cantidadMinima: dto.cantidadMinima ?? 0,
						cantidadReservada: 0,
					},
				});
			}

			return material;
		});
	}

	async update(id: string, dto: UpdateMaterialDto, _currentUser: AuthUser) {
		const existing = await this.prisma.material.findUnique({ where: { id } });
		if (!existing) throw new NotFoundException('Material no encontrado');

		if (dto.codigo) {
			const clash = await this.prisma.material.findFirst({
				where: {
					codigo: dto.codigo.trim().toUpperCase(),
					id: { not: id },
				},
			});
			if (clash) {
				throw new BadRequestException('Ya existe un material con ese código');
			}
		}

		return this.prisma.material.update({
			where: { id },
			data: {
				codigo: dto.codigo?.trim().toUpperCase(),
				nombre: dto.nombre?.trim(),
				marca: dto.marca === undefined ? undefined : dto.marca?.trim() || null,
				uso: dto.uso?.trim(),
				unidadId: dto.unidadId,
				precioActual: dto.precioActual,
				activo: dto.activo,
			},
			include: { unidad: true },
		});
	}
}
