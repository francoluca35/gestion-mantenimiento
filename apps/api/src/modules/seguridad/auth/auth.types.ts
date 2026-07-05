export interface AuthUser {
	id: string;
	nombreUsuario: string;
	email: string | null;
	sucursalId: string | null;
	sectorId: string | null;
	perfilId: string | null;
	esAdministrador: boolean;
	supervisaSucursales: boolean;
	supervisaSolicitudesOt: string;
	supervisaSolicitudesOc: boolean;
	montoMaximoOc: string | null;
	derechos: string[];
	sucursal: { id: string; nombre: string; codigo: string } | null;
	perfil: { id: string; nombre: string } | null;
}

export interface JwtPayload {
	sub: string;
	nombreUsuario: string;
	type: 'access' | 'refresh';
}
