import {
	ConflictException,
	ForbiddenException,
	Injectable,
	NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../database/prisma.service';
import { AuthUser } from '../auth/auth.types';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';

@Injectable()
export class UsuariosService {
	constructor(private readonly prisma: PrismaService) {}

	async findAll(currentUser: AuthUser) {
		const where: Prisma.UsuarioWhereInput = {};

		if (!currentUser.esAdministrador && !currentUser.supervisaSucursales) {
			where.sucursalId = currentUser.sucursalId ?? undefined;
		}

		const usuarios = await this.prisma.usuario.findMany({
			where,
			include: {
				sucursal: true,
				perfil: true,
			},
			orderBy: { nombreUsuario: 'asc' },
		});

		return usuarios.map((usuario) => this.toResponse(usuario));
	}

	async findOne(id: string, currentUser: AuthUser) {
		const usuario = await this.prisma.usuario.findUnique({
			where: { id },
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		if (!usuario) {
			throw new NotFoundException('Usuario no encontrado');
		}

		this.assertCanAccess(currentUser, usuario.sucursalId);
		return this.toResponse(usuario);
	}

	async create(dto: CreateUsuarioDto, currentUser: AuthUser) {
		this.assertCanManage(currentUser, dto.sucursalId ?? null);

		const exists = await this.prisma.usuario.findUnique({
			where: { nombreUsuario: dto.nombreUsuario },
		});
		if (exists) {
			throw new ConflictException('El nombre de usuario ya existe');
		}

		if (dto.esAdministrador && !currentUser.esAdministrador) {
			throw new ForbiddenException('Solo un administrador puede crear administradores');
		}

		const claveHash = await bcrypt.hash(dto.clave, 10);
		const usuario = await this.prisma.usuario.create({
			data: {
				nombreUsuario: dto.nombreUsuario,
				claveHash,
				email: dto.email,
				sucursalId: dto.sucursalId,
				sectorId: dto.sectorId,
				perfilId: dto.perfilId,
				esAdministrador: dto.esAdministrador ?? false,
				supervisaSucursales: dto.supervisaSucursales ?? false,
				supervisaSolicitudesOt: dto.supervisaSolicitudesOt,
				supervisaSolicitudesOc: dto.supervisaSolicitudesOc ?? false,
				montoMaximoOc: dto.montoMaximoOc,
			},
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		return this.toResponse(usuario);
	}

	async update(id: string, dto: UpdateUsuarioDto, currentUser: AuthUser) {
		const existing = await this.prisma.usuario.findUnique({ where: { id } });
		if (!existing) {
			throw new NotFoundException('Usuario no encontrado');
		}

		this.assertCanManage(currentUser, existing.sucursalId);

		if (dto.esAdministrador && !currentUser.esAdministrador) {
			throw new ForbiddenException('Solo un administrador puede modificar ese flag');
		}

		const data: Prisma.UsuarioUpdateInput = {
			email: dto.email,
			esAdministrador: dto.esAdministrador,
			supervisaSucursales: dto.supervisaSucursales,
			supervisaSolicitudesOt: dto.supervisaSolicitudesOt,
			supervisaSolicitudesOc: dto.supervisaSolicitudesOc,
			activo: dto.activo,
		};

		if (dto.clave) {
			data.claveHash = await bcrypt.hash(dto.clave, 10);
		}

		if (dto.sucursalId !== undefined) {
			data.sucursal = dto.sucursalId
				? { connect: { id: dto.sucursalId } }
				: { disconnect: true };
		}

		if (dto.perfilId !== undefined) {
			data.perfil = dto.perfilId
				? { connect: { id: dto.perfilId } }
				: { disconnect: true };
		}

		if (dto.sectorId !== undefined) {
			data.sectorId = dto.sectorId;
		}

		if (dto.montoMaximoOc !== undefined) {
			data.montoMaximoOc = dto.montoMaximoOc;
		}

		const usuario = await this.prisma.usuario.update({
			where: { id },
			data,
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		return this.toResponse(usuario);
	}

	async deactivate(id: string, currentUser: AuthUser) {
		const existing = await this.prisma.usuario.findUnique({ where: { id } });
		if (!existing) {
			throw new NotFoundException('Usuario no encontrado');
		}

		this.assertCanManage(currentUser, existing.sucursalId);

		if (existing.id === currentUser.id) {
			throw new ForbiddenException('No podés desactivar tu propio usuario');
		}

		const usuario = await this.prisma.usuario.update({
			where: { id },
			data: { activo: false },
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		return this.toResponse(usuario);
	}

	private assertCanAccess(currentUser: AuthUser, sucursalId: string | null) {
		if (currentUser.esAdministrador || currentUser.supervisaSucursales) {
			return;
		}

		if (sucursalId !== currentUser.sucursalId) {
			throw new ForbiddenException('No podés acceder a usuarios de otra sucursal');
		}
	}

	private assertCanManage(currentUser: AuthUser, sucursalId: string | null) {
		this.assertCanAccess(currentUser, sucursalId);
	}

	private toResponse(usuario: {
		id: string;
		nombreUsuario: string;
		email: string | null;
		sucursalId: string | null;
		sectorId: string | null;
		perfilId: string | null;
		esAdministrador: boolean;
		supervisaSucursales: boolean;
		supervisaSolicitudesOt: string;
		supervisaSolicitudesOc: boolean;
		montoMaximoOc: { toString(): string } | null;
		activo: boolean;
		sucursal: { id: string; nombre: string; codigo: string } | null;
		perfil: { id: string; nombre: string } | null;
	}) {
		return {
			id: usuario.id,
			nombreUsuario: usuario.nombreUsuario,
			email: usuario.email,
			sucursalId: usuario.sucursalId,
			sectorId: usuario.sectorId,
			perfilId: usuario.perfilId,
			esAdministrador: usuario.esAdministrador,
			supervisaSucursales: usuario.supervisaSucursales,
			supervisaSolicitudesOt: usuario.supervisaSolicitudesOt,
			supervisaSolicitudesOc: usuario.supervisaSolicitudesOc,
			montoMaximoOc: usuario.montoMaximoOc?.toString() ?? null,
			activo: usuario.activo,
			sucursal: usuario.sucursal,
			perfil: usuario.perfil,
		};
	}
}
