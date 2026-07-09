import { Body, Controller, Delete, Param, Post } from '@nestjs/common';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { AuthUser } from '../seguridad/auth/auth.types';

import { RegistrarFcmTokenDto } from './dto/registrar-fcm-token.dto';
import { NotificacionesService } from './notificaciones.service';

@Controller('dispositivos')
export class NotificacionesController {
	constructor(private readonly notificacionesService: NotificacionesService) {}

	@Post('fcm')
	registrarFcmToken(
		@Body() dto: RegistrarFcmTokenDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.notificacionesService.registrarFcmToken(user.id, dto.token);
	}

	@Delete('fcm/:token')
	registrarEliminarFcmToken(
		@Param('token') token: string,
		@CurrentUser() user: AuthUser,
	) {
		return this.notificacionesService.eliminarFcmToken(user.id, token);
	}
}

