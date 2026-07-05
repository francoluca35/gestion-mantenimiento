import {
	CanActivate,
	ExecutionContext,
	ForbiddenException,
	Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { DERECHO_KEY } from '../decorators/requiere-derecho.decorator';
import type { AuthUser } from '../../modules/seguridad/auth/auth.types';
import { PermisosService } from '../../modules/seguridad/permisos/permisos.service';

@Injectable()
export class DerechoGuard implements CanActivate {
	constructor(
		private readonly reflector: Reflector,
		private readonly permisosService: PermisosService,
	) {}

	async canActivate(context: ExecutionContext): Promise<boolean> {
		const codigo = this.reflector.getAllAndOverride<string>(DERECHO_KEY, [
			context.getHandler(),
			context.getClass(),
		]);

		if (!codigo) {
			return true;
		}

		const request = context.switchToHttp().getRequest<{ user: AuthUser }>();
		const user = request.user;

		if (!user) {
			throw new ForbiddenException('No autenticado');
		}

		const permitido = await this.permisosService.tieneDerecho(
			user.perfilId,
			user.esAdministrador,
			codigo,
		);

		if (!permitido) {
			throw new ForbiddenException(`Sin permiso: ${codigo}`);
		}

		return true;
	}
}
