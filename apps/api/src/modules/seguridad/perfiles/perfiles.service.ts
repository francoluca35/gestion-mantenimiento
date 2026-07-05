import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import { CreatePerfilDto } from './dto/create-perfil.dto';
import { UpdatePerfilDerechosDto } from './dto/update-perfil-derechos.dto';
import { UpdatePerfilDto } from './dto/update-perfil.dto';

@Injectable()
export class PerfilesService {
	constructor(private readonly prisma: PrismaService) {}

	findAll() {
		return this.prisma.perfil.findMany({
			orderBy: { nombre: 'asc' },
			include: {
				_count: { select: { usuarios: true, derechos: true } },
			},
		});
	}

	async findOne(id: string) {
		const perfil = await this.prisma.perfil.findUnique({
			where: { id },
			include: {
				_count: { select: { usuarios: true, derechos: true } },
			},
		});

		if (!perfil) {
			throw new NotFoundException('Perfil no encontrado');
		}

		return perfil;
	}

	create(dto: CreatePerfilDto) {
		return this.prisma.perfil.create({
			data: {
				nombre: dto.nombre,
				descripcion: dto.descripcion,
			},
		});
	}

	async update(id: string, dto: UpdatePerfilDto) {
		await this.findOne(id);
		return this.prisma.perfil.update({
			where: { id },
			data: dto,
		});
	}

	async remove(id: string) {
		await this.findOne(id);
		return this.prisma.perfil.update({
			where: { id },
			data: { activo: false },
		});
	}

	async getDerechos(id: string) {
		await this.findOne(id);

		const derechos = await this.prisma.derecho.findMany({
			orderBy: [{ orden: 'asc' }, { codigo: 'asc' }],
		});

		const asignados = await this.prisma.perfilDerecho.findMany({
			where: { perfilId: id },
		});

		const asignadoMap = new Map(
			asignados.map((item) => [item.derechoId, item]),
		);

		const nodes = derechos.map((derecho) => {
			const asignado = asignadoMap.get(derecho.id);
			return {
				id: derecho.id,
				parentId: derecho.parentId,
				codigo: derecho.codigo,
				nombre: derecho.nombre,
				orden: derecho.orden,
				habilitado: asignado?.habilitado ?? false,
				modoTotal: asignado?.modoTotal ?? false,
			};
		});

		return this.buildTree(nodes);
	}

	async updateDerechos(id: string, dto: UpdatePerfilDerechosDto) {
		await this.findOne(id);

		await this.prisma.$transaction(async (tx) => {
			await tx.perfilDerecho.deleteMany({ where: { perfilId: id } });

			if (dto.derechos.length === 0) {
				return;
			}

			await tx.perfilDerecho.createMany({
				data: dto.derechos.map((item) => ({
					perfilId: id,
					derechoId: item.derechoId,
					habilitado: item.habilitado,
					modoTotal: item.modoTotal,
				})),
			});
		});

		return this.getDerechos(id);
	}

	private buildTree(
		nodes: Array<{
			id: string;
			parentId: string | null;
			codigo: string;
			nombre: string;
			orden: number;
			habilitado: boolean;
			modoTotal: boolean;
		}>,
	) {
		type TreeNode = (typeof nodes)[number] & { children: TreeNode[] };
		const map = new Map<string, TreeNode>();
		const roots: TreeNode[] = [];

		for (const node of nodes) {
			map.set(node.id, { ...node, children: [] });
		}

		for (const node of nodes) {
			const current = map.get(node.id)!;
			if (node.parentId && map.has(node.parentId)) {
				map.get(node.parentId)!.children.push(current);
			} else {
				roots.push(current);
			}
		}

		return roots;
	}
}
