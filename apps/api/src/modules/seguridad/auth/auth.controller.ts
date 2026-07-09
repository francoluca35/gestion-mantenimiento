import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Public } from '../../../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import type { AuthUser } from './auth.types';
import { CambiarClaveDto } from './dto/cambiar-clave.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';

@Controller('auth')
export class AuthController {
	constructor(private readonly authService: AuthService) {}

	@Public()
	@Post('login')
	login(@Body() dto: LoginDto) {
		return this.authService.login(dto);
	}

	@Public()
	@Post('refresh')
	refresh(@Body() dto: RefreshDto) {
		return this.authService.refresh(dto.refreshToken ?? '');
	}

	@Post('logout')
	logout(@CurrentUser() user: AuthUser, @Body() dto: RefreshDto) {
		return this.authService.logout(user.id, dto.refreshToken);
	}

	@Get('me')
	me(@CurrentUser() user: AuthUser) {
		return this.authService.me(user.id);
	}

	@Patch('clave')
	cambiarClave(@CurrentUser() user: AuthUser, @Body() dto: CambiarClaveDto) {
		return this.authService.cambiarClave(user.id, dto);
	}

	@Get('sesiones')
	listarSesiones(@CurrentUser() user: AuthUser) {
		return this.authService.listarSesiones(user.id);
	}

	@Post('sesiones/revocar-todas')
	revocarSesiones(@CurrentUser() user: AuthUser) {
		return this.authService.revocarTodasLasSesiones(user.id);
	}
}
