import {
	BadRequestException,
	Injectable,
	UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomUUID } from 'crypto';
import { PrismaService } from '../../../database/prisma.service';
import { PermisosService } from '../permisos/permisos.service';
import { AuthUser, JwtPayload } from './auth.types';
import { LoginDto } from './dto/login.dto';
import { CambiarClaveDto } from './dto/cambiar-clave.dto';

@Injectable()
export class AuthService {
	constructor(
		private readonly prisma: PrismaService,
		private readonly jwtService: JwtService,
		private readonly config: ConfigService,
		private readonly permisosService: PermisosService,
	) {}

	async login(dto: LoginDto) {
		const usuario = await this.prisma.usuario.findUnique({
			where: { nombreUsuario: dto.nombreUsuario },
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		if (!usuario || !usuario.activo) {
			throw new UnauthorizedException('Usuario o clave incorrectos');
		}

		const valid = await bcrypt.compare(dto.clave, usuario.claveHash);
		if (!valid) {
			throw new UnauthorizedException('Usuario o clave incorrectos');
		}

		const authUser = await this.toAuthUser(usuario);
		const tokens = await this.issueTokens(authUser);

		return {
			...tokens,
			usuario: authUser,
		};
	}

	async me(userId: string): Promise<AuthUser> {
		const usuario = await this.prisma.usuario.findUnique({
			where: { id: userId },
			include: {
				sucursal: true,
				perfil: true,
			},
		});

		if (!usuario || !usuario.activo) {
			throw new UnauthorizedException('Sesión inválida');
		}

		return this.toAuthUser(usuario);
	}

	async refresh(refreshToken: string) {
		let payload: JwtPayload;
		try {
			payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
				secret: this.config.get<string>('JWT_REFRESH_SECRET'),
			});
		} catch {
			throw new UnauthorizedException('Refresh token inválido');
		}

		if (payload.type !== 'refresh') {
			throw new UnauthorizedException('Refresh token inválido');
		}

		const tokenHash = this.hashToken(refreshToken);
		const sesion = await this.prisma.sesion.findFirst({
			where: {
				usuarioId: payload.sub,
				refreshTokenHash: tokenHash,
				revocada: false,
				expiresAt: { gt: new Date() },
			},
		});

		if (!sesion) {
			throw new UnauthorizedException('Sesión expirada o revocada');
		}

		await this.prisma.sesion.update({
			where: { id: sesion.id },
			data: { revocada: true },
		});

		const authUser = await this.me(payload.sub);
		return this.issueTokens(authUser);
	}

	async logout(userId: string, refreshToken?: string) {
		if (refreshToken) {
			const tokenHash = this.hashToken(refreshToken);
			await this.prisma.sesion.updateMany({
				where: {
					usuarioId: userId,
					refreshTokenHash: tokenHash,
					revocada: false,
				},
				data: { revocada: true },
			});
			return { ok: true };
		}

		await this.prisma.sesion.updateMany({
			where: { usuarioId: userId, revocada: false },
			data: { revocada: true },
		});

		return { ok: true };
	}

	async validateUserById(userId: string): Promise<AuthUser> {
		return this.me(userId);
	}

	async cambiarClave(userId: string, dto: CambiarClaveDto) {
		const usuario = await this.prisma.usuario.findUnique({
			where: { id: userId },
		});

		if (!usuario || !usuario.activo) {
			throw new UnauthorizedException('Sesión inválida');
		}

		const valid = await bcrypt.compare(dto.claveActual, usuario.claveHash);
		if (!valid) {
			throw new UnauthorizedException('La clave actual es incorrecta');
		}

		if (dto.claveActual === dto.claveNueva) {
			throw new BadRequestException('La clave nueva debe ser distinta a la actual');
		}

		await this.prisma.usuario.update({
			where: { id: userId },
			data: { claveHash: await bcrypt.hash(dto.claveNueva, 10) },
		});

		await this.prisma.sesion.updateMany({
			where: { usuarioId: userId, revocada: false },
			data: { revocada: true },
		});

		return { ok: true };
	}

	async listarSesiones(userId: string) {
		const sesiones = await this.prisma.sesion.findMany({
			where: { usuarioId: userId },
			orderBy: { createdAt: 'desc' },
			take: 20,
			select: {
				id: true,
				createdAt: true,
				expiresAt: true,
				revocada: true,
			},
		});

		return sesiones;
	}

	async revocarTodasLasSesiones(userId: string) {
		await this.prisma.sesion.updateMany({
			where: { usuarioId: userId, revocada: false },
			data: { revocada: true },
		});
		return { ok: true };
	}

	private async issueTokens(user: AuthUser) {
		const accessPayload: JwtPayload = {
			sub: user.id,
			nombreUsuario: user.nombreUsuario,
			type: 'access',
		};

		const refreshPayload: JwtPayload = {
			sub: user.id,
			nombreUsuario: user.nombreUsuario,
			type: 'refresh',
		};

		const accessToken = await this.jwtService.signAsync(accessPayload, {
			secret: this.config.get<string>('JWT_SECRET'),
			expiresIn: '8h',
		});

		const refreshToken = await this.jwtService.signAsync(refreshPayload, {
			secret: this.config.get<string>('JWT_REFRESH_SECRET'),
			expiresIn: '7d',
		});

		const expiresAt = new Date();
		expiresAt.setDate(expiresAt.getDate() + 7);

		await this.prisma.sesion.create({
			data: {
				id: randomUUID(),
				usuarioId: user.id,
				refreshTokenHash: this.hashToken(refreshToken),
				expiresAt,
			},
		});

		return {
			accessToken,
			refreshToken,
		};
	}

	private async toAuthUser(usuario: {
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
		sucursal: { id: string; nombre: string; codigo: string } | null;
		perfil: { id: string; nombre: string } | null;
	}): Promise<AuthUser> {
		const derechos = await this.permisosService.getDerechosEfectivos(
			usuario.perfilId,
			usuario.esAdministrador,
		);

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
			derechos,
			sucursal: usuario.sucursal
				? {
						id: usuario.sucursal.id,
						nombre: usuario.sucursal.nombre,
						codigo: usuario.sucursal.codigo,
					}
				: null,
			perfil: usuario.perfil
				? {
						id: usuario.perfil.id,
						nombre: usuario.perfil.nombre,
					}
				: null,
		};
	}

	private hashToken(token: string): string {
		return createHash('sha256').update(token).digest('hex');
	}
}
