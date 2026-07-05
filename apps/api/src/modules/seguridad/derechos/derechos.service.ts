import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';

@Injectable()
export class DerechosService {
	constructor(private readonly prisma: PrismaService) {}

	async getTree() {
		const derechos = await this.prisma.derecho.findMany({
			orderBy: [{ orden: 'asc' }, { codigo: 'asc' }],
		});

		type TreeNode = (typeof derechos)[number] & { children: TreeNode[] };
		const map = new Map<string, TreeNode>();
		const roots: TreeNode[] = [];

		for (const derecho of derechos) {
			map.set(derecho.id, { ...derecho, children: [] });
		}

		for (const derecho of derechos) {
			const current = map.get(derecho.id)!;
			if (derecho.parentId && map.has(derecho.parentId)) {
				map.get(derecho.parentId)!.children.push(current);
			} else {
				roots.push(current);
			}
		}

		return roots;
	}
}
