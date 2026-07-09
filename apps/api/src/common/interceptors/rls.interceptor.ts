import {
	CallHandler,
	ExecutionContext,
	Injectable,
	NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { rlsContext } from '../../database/rls-context';
import type { AuthUser } from '../../modules/seguridad/auth/auth.types';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class RlsInterceptor implements NestInterceptor {
	constructor(private readonly reflector: Reflector) {}

	intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
		const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
			context.getHandler(),
			context.getClass(),
		]);

		const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
		const user = request.user;

		const store = {
			bypass: isPublic || !user,
			sucursalId: user?.sucursalId ?? null,
			esAdministrador: user?.esAdministrador ?? false,
			supervisaSucursales: user?.supervisaSucursales ?? false,
		};

		return new Observable((subscriber) => {
			rlsContext.run(store, () => {
				next.handle().subscribe({
					next: (value) => subscriber.next(value),
					error: (err) => subscriber.error(err),
					complete: () => subscriber.complete(),
				});
			});
		});
	}
}
