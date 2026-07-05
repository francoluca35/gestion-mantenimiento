import { Body, Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Public } from '../../../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import type { AuthUser } from './auth.types';
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
}
