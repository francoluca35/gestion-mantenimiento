import { Global, Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { RlsInterceptor } from '../common/interceptors/rls.interceptor';
import { PrismaService } from './prisma.service';

@Global()
@Module({
	providers: [
		PrismaService,
		{
			provide: APP_INTERCEPTOR,
			useClass: RlsInterceptor,
		},
	],
	exports: [PrismaService],
})
export class PrismaModule {}
