import {
	ConflictException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import { AuthUser } from '../auth/auth.types';
import { CreateSucursalDto } from './dto/create-sucursal.dto';
import { UpdateSucursalDto } from './dto/update-sucursal.dto';

@Injectable()
export class SucursalesService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(currentUser: AuthUser) {
		if (currentUser.esAdministrador || currentUser.supervisaSucursales) {
			return this.prisma.sucursal.findMany({
				orderBy: { nombre: 'asc' },
				include: { _count: { select: { usuarios: true } } },
			});
		}

		if (!currentUser.sucursalId) {
			return [];
		}

		return this.prisma.sucursal.findMany({
			where: { id: currentUser.sucursalId },
			include: { _count: { select: { usuarios: true } } },
		});
	}

	async findOne(id: string) {
		const sucursal = await this.prisma.sucursal.findUnique({
			where: { id },
			include: { _count: { select: { usuarios: true } } },
		});

		if (!sucursal) {
			throw new NotFoundException('Sucursal no encontrada');
		}

		return sucursal;
	}

	async create(dto: CreateSucursalDto) {
		const exists = await this.prisma.sucursal.findUnique({
			where: { codigo: dto.codigo },
		});
		if (exists) {
			throw new ConflictException('El código de sucursal ya existe');
		}

		return this.prisma.sucursal.create({
			data: {
				nombre: dto.nombre,
				codigo: dto.codigo.toUpperCase(),
			},
		});
	}

	async update(id: string, dto: UpdateSucursalDto) {
		await this.findOne(id);
		return this.prisma.sucursal.update({
			where: { id },
			data: dto,
		});
	}

	async remove(id: string) {
		await this.findOne(id);
		return this.prisma.sucursal.update({
			where: { id },
			data: { activa: false },
		});
	}
}
