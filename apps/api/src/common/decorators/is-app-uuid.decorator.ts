import { Matches } from 'class-validator';

/** Acepta UUIDs del seed demo y los generados por Prisma. */
export const IsAppUuid = () =>
	Matches(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, {
		message: '$property must be a UUID',
	});
