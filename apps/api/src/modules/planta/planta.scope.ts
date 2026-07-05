import { ForbiddenException } from '@nestjs/common';
import type { AuthUser } from '../seguridad/auth/auth.types';

export function resolveSucursalId(
	currentUser: AuthUser,
	requestedSucursalId?: string,
): string {
	if (currentUser.esAdministrador || currentUser.supervisaSucursales) {
		const sucursalId = requestedSucursalId ?? currentUser.sucursalId;
		if (!sucursalId) {
			throw new ForbiddenException(
				'Indicá sucursalId (admin global sin sucursal fija)',
			);
		}
		return sucursalId;
	}

	if (!currentUser.sucursalId) {
		throw new ForbiddenException('Usuario sin sucursal asignada');
	}

	if (requestedSucursalId && requestedSucursalId !== currentUser.sucursalId) {
		throw new ForbiddenException('No podés operar en otra sucursal');
	}

	return currentUser.sucursalId;
}

export function assertSucursalAccess(currentUser: AuthUser, sucursalId: string) {
	if (currentUser.esAdministrador || currentUser.supervisaSucursales) {
		return;
	}

	if (currentUser.sucursalId !== sucursalId) {
		throw new ForbiddenException('No podés acceder a datos de otra sucursal');
	}
}
