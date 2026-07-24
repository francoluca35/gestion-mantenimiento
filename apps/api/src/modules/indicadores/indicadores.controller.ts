import { Controller, Get, Query } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../seguridad/auth/auth.types';
import { IndicadoresService } from './indicadores.service';

@Controller('indicadores')
export class IndicadoresController {
	constructor(private readonly service: IndicadoresService) {}

	@Get('dashboard')
	@RequiereDerecho('programacion.ordenes_trabajo.buscar_y_actualizar')
	dashboard(
		@CurrentUser() user: AuthUser,
		@Query('sucursalId') sucursalId?: string,
	) {
		return this.service.dashboard(user, sucursalId);
	}
}
