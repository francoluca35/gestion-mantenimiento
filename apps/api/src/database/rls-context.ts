import { AsyncLocalStorage } from 'async_hooks';

export type RlsContext = {
	bypass: boolean;
	sucursalId: string | null;
	esAdministrador: boolean;
	supervisaSucursales: boolean;
};

export const rlsContext = new AsyncLocalStorage<RlsContext>();

export function getRlsContext(): RlsContext | undefined {
	return rlsContext.getStore();
}
