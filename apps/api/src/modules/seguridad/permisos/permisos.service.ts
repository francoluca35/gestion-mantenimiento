import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';

@Injectable()
export class PermisosService {
	constructor(private readonly prisma: PrismaService) {}

	async getDerechosEfectivos(perfilId: string | null, esAdministrador: boolean): Promise<string[]> {
		if (esAdministrador) {
			const all = await this.prisma.derecho.findMany({ select: { codigo: true } });
			return all.map((item) => item.codigo);
		}

		if (!perfilId) {
			return [];
		}

		const asignados = await this.prisma.perfilDerecho.findMany({
			where: { perfilId, habilitado: true },
			include: { derecho: true },
		});

		const derechos = await this.prisma.derecho.findMany({
			orderBy: { orden: 'asc' },
		});

		const byId = new Map(derechos.map((item) => [item.id, item]));
		const byCodigo = new Map(derechos.map((item) => [item.codigo, item]));
		const childrenByParent = new Map<string | null, typeof derechos>();

		for (const derecho of derechos) {
			const list = childrenByParent.get(derecho.parentId) ?? [];
			list.push(derecho);
			childrenByParent.set(derecho.parentId, list);
		}

		const enabled = new Set<string>();

		for (const asignado of asignados) {
			enabled.add(asignado.derecho.codigo);
			if (asignado.modoTotal) {
				this.collectDescendants(asignado.derechoId, childrenByParent, enabled);
			}
		}

		// Ancestros en modo total también habilitan el código pedido
		for (const asignado of asignados) {
			if (!asignado.modoTotal) continue;
			let current = byId.get(asignado.derechoId);
			while (current?.parentId) {
				current = byId.get(current.parentId);
			}
		}

		// Resolver por ancestros: si un padre tiene modoTotal, todos los hijos están
		for (const derecho of derechos) {
			if (enabled.has(derecho.codigo)) continue;
			let parentId = derecho.parentId;
			while (parentId) {
				const parent = byId.get(parentId);
				if (!parent) break;
				const parentAsignado = asignados.find((item) => item.derechoId === parent.id);
				if (parentAsignado?.habilitado && parentAsignado.modoTotal) {
					enabled.add(derecho.codigo);
					break;
				}
				parentId = parent.parentId;
			}
		}

		void byCodigo;
		return [...enabled].sort();
	}

	async tieneDerecho(
		perfilId: string | null,
		esAdministrador: boolean,
		codigo: string,
	): Promise<boolean> {
		if (esAdministrador) {
			return true;
		}

		const derechos = await this.getDerechosEfectivos(perfilId, esAdministrador);
		return derechos.includes(codigo);
	}

	private collectDescendants(
		parentId: string,
		childrenByParent: Map<string | null, { id: string; codigo: string; parentId: string | null }[]>,
		enabled: Set<string>,
	) {
		const children = childrenByParent.get(parentId) ?? [];
		for (const child of children) {
			enabled.add(child.codigo);
			this.collectDescendants(child.id, childrenByParent, enabled);
		}
	}
}
