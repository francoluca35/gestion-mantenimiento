import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class NotificacionesService {
	constructor(private readonly prisma: PrismaService) {}

	async registrarFcmToken(usuarioId: string, token: string) {
		const trimmed = token.trim();
		if (trimmed.length < 10) {
			throw new BadRequestException('Token FCM inválido');
		}

		return this.prisma.dispositivoFcm.upsert({
			where: { token: trimmed },
			update: { usuarioId },
			create: { usuarioId, token: trimmed },
		});
	}

	async eliminarFcmToken(usuarioId: string, token: string) {
		const trimmed = token.trim();
		await this.prisma.dispositivoFcm.deleteMany({
			where: { usuarioId, token: trimmed },
		});
		return { ok: true };
	}
}

