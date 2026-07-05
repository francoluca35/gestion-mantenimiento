import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { StorageModule } from './modules/storage/storage.module';

@Module({
	imports: [
		ConfigModule.forRoot({
			isGlobal: true,
			envFilePath: ['../../.env', '.env'],
		}),
		StorageModule,
	],
	controllers: [AppController],
	providers: [AppService],
})
export class AppModule {}
