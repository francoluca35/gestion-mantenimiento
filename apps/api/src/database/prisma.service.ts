import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';
import { getRlsContext } from './rls-context';

const CLIENT_KEY = Symbol('prismaClient');

function createRlsClient() {
	const base = new PrismaClient();

	return base.$extends({
		query: {
			$allModels: {
				async $allOperations({
					args,
					query,
				}: {
					args: unknown;
					query: (a: unknown) => Prisma.PrismaPromise<unknown>;
				}) {
					const ctx = getRlsContext();
					if (!ctx) {
						return query(args);
					}

					const preamble: Prisma.PrismaPromise<number>[] = [
						base.$executeRaw`SELECT set_config('app.bypass_rls', ${ctx.bypass ? 'true' : 'false'}, true)`,
					];

					if (!ctx.bypass) {
						preamble.push(
							base.$executeRaw`SELECT set_config('app.current_sucursal_id', ${ctx.sucursalId ?? ''}, true)`,
							base.$executeRaw`SELECT set_config('app.es_admin_global', ${String(ctx.esAdministrador)}, true)`,
							base.$executeRaw`SELECT set_config('app.supervisa_sucursales', ${String(ctx.supervisaSucursales)}, true)`,
						);
					}

					const results = await base.$transaction([
						...preamble,
						query(args),
					] as Prisma.PrismaPromise<unknown>[]);

					return results[results.length - 1];
				},
			},
		},
	});
}

export type ExtendedPrismaClient = ReturnType<typeof createRlsClient>;

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
	constructor() {
		const client = createRlsClient();
		(this as unknown as Record<symbol, ExtendedPrismaClient>)[CLIENT_KEY] = client;
		Object.assign(this, client);
	}

	private get client(): ExtendedPrismaClient {
		return (this as unknown as Record<symbol, ExtendedPrismaClient>)[CLIENT_KEY];
	}

	async onModuleInit() {
		await this.client.$connect();
	}

	async onModuleDestroy() {
		await this.client.$disconnect();
	}

	// Los métodos $ del cliente extendido no se copian con Object.assign,
	// por eso el readiness usa el cliente interno directamente.
	async ping(): Promise<void> {
		await this.client.$queryRaw`SELECT 1`;
	}
}

export interface PrismaService extends ExtendedPrismaClient {}
