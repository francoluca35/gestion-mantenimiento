import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { DerechoGuard } from '../../common/guards/derecho.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { JwtStrategy } from './auth/jwt.strategy';
import { DerechosController } from './derechos/derechos.controller';
import { DerechosService } from './derechos/derechos.service';
import { PerfilesController } from './perfiles/perfiles.controller';
import { PerfilesService } from './perfiles/perfiles.service';
import { PermisosService } from './permisos/permisos.service';
import { SucursalesController } from './sucursales/sucursales.controller';
import { SucursalesService } from './sucursales/sucursales.service';
import { UsuariosController } from './usuarios/usuarios.controller';
import { UsuariosService } from './usuarios/usuarios.service';

@Module({
	imports: [
		PassportModule.register({ defaultStrategy: 'jwt' }),
		JwtModule.registerAsync({
			imports: [ConfigModule],
			inject: [ConfigService],
			useFactory: (config: ConfigService) => ({
				secret: config.get<string>('JWT_SECRET'),
			}),
		}),
	],
	controllers: [
		AuthController,
		UsuariosController,
		PerfilesController,
		DerechosController,
		SucursalesController,
	],
	providers: [
		AuthService,
		JwtStrategy,
		PermisosService,
		UsuariosService,
		PerfilesService,
		DerechosService,
		SucursalesService,
		{
			provide: APP_GUARD,
			useClass: JwtAuthGuard,
		},
		{
			provide: APP_GUARD,
			useClass: DerechoGuard,
		},
	],
	exports: [AuthService, PermisosService],
})
export class SeguridadModule {}
