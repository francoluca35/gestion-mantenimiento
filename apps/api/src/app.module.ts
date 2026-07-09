import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './database/prisma.module';
import { MantenimientoModule } from './modules/mantenimiento/mantenimiento.module';
import { PlantaModule } from './modules/planta/planta.module';
import { SeguridadModule } from './modules/seguridad/seguridad.module';
import { StorageModule } from './modules/storage/storage.module';
import { NotificacionesModule } from './modules/notificaciones/notificaciones.module';

@Module({
	imports: [
		ConfigModule.forRoot({
			isGlobal: true,
			envFilePath: ['.env', '../../.env'],
		}),
		PrismaModule,
		SeguridadModule,
		PlantaModule,
		MantenimientoModule,
		NotificacionesModule,
		StorageModule,
	],
	controllers: [AppController],
	providers: [AppService],
})
export class AppModule {}
