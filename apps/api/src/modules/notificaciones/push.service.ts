import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

// firebase-admin tipado laxo: el default export varía entre ESM/CJS.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const admin = require('firebase-admin') as any;

@Injectable()
export class PushService implements OnModuleInit {
	private readonly logger = new Logger(PushService.name);
	private ready = false;

	constructor(private readonly prisma: PrismaService) {}

	onModuleInit() {
		this.ensureFirebase();
		if (this.ready) {
			this.logger.log('FCM listo (credenciales cargadas)');
		} else {
			this.logger.warn(
				'FCM deshabilitado — definir FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL y FIREBASE_PRIVATE_KEY',
			);
		}
	}

	isEnabled() {
		return this.ready;
	}

	/** Una OT asignada. */
	async notifyOtAsignada(otNumero: number, tecnicoId: string) {
		return this.notifyOtAsignadas(tecnicoId, [otNumero]);
	}

	/**
	 * Varias OT al mismo técnico (p. ej. emisión en lote).
	 * Una sola notificación resumen para no spamear.
	 */
	async notifyOtAsignadas(tecnicoId: string, otNumeros: number[]) {
		const numeros = [...new Set(otNumeros.filter((n) => Number.isFinite(n)))];
		if (numeros.length === 0) return { sent: 0, failed: 0, disabled: !this.ready };

		const tecnico = await this.prisma.usuario.findUnique({
			where: { id: tecnicoId },
			select: { nombreUsuario: true },
		});

		const dispositivos = await this.prisma.dispositivoFcm.findMany({
			where: { usuarioId: tecnicoId },
			select: { id: true, token: true },
		});

		if (dispositivos.length === 0) {
			this.logger.debug(
				`Sin tokens FCM para ${tecnico?.nombreUsuario ?? tecnicoId}`,
			);
			return { sent: 0, failed: 0, disabled: !this.ready };
		}

		const title =
			numeros.length === 1 ? `OT #${numeros[0]}` : `${numeros.length} OT asignadas`;
		const body =
			numeros.length === 1
				? 'Nueva orden de trabajo asignada'
				: `Te asignaron las OT ${numeros.map((n) => `#${n}`).join(', ')}`;

		if (!this.ready) {
			this.logger.log(
				`[push:disabled] ${title} → ${tecnico?.nombreUsuario ?? tecnicoId}`,
			);
			return { sent: 0, failed: 0, disabled: true };
		}

		const tokens = dispositivos.map((d: { token: string }) => d.token);

		try {
			const messaging = admin.messaging();
			const send =
				typeof messaging.sendEachForMulticast === 'function'
					? messaging.sendEachForMulticast.bind(messaging)
					: messaging.sendMulticast.bind(messaging);

			const response = await send({
				tokens,
				notification: { title, body },
				data: {
					type: 'ot.asignada',
					otNumero: String(numeros[0]),
					otNumeros: numeros.join(','),
					click_action: 'FLUTTER_NOTIFICATION_CLICK',
				},
				android: {
					priority: 'high',
					notification: {
						channelId: 'ot_asignadas',
						clickAction: 'FLUTTER_NOTIFICATION_CLICK',
					},
				},
			});

			await this.pruneInvalidTokens(dispositivos, response.responses ?? []);

			this.logger.log(
				`[push] ${title} → ${tecnico?.nombreUsuario ?? tecnicoId} — ok ${response.successCount} / fail ${response.failureCount}`,
			);

			return {
				sent: response.successCount as number,
				failed: response.failureCount as number,
				disabled: false,
			};
		} catch (error) {
			this.logger.warn(`[push:error] ${String(error)}`);
			return { sent: 0, failed: tokens.length, disabled: false };
		}
	}

	private ensureFirebase() {
		if (this.ready) return;

		const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
		const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
		const privateKeyRaw = process.env.FIREBASE_PRIVATE_KEY;

		if (!projectId || !clientEmail || !privateKeyRaw) {
			this.ready = false;
			return;
		}

		const privateKey = privateKeyRaw.replace(/\\n/g, '\n');

		if (!admin.apps?.length) {
			admin.initializeApp({
				credential: admin.credential.cert({
					projectId,
					clientEmail,
					privateKey,
				}),
			});
		}

		this.ready = true;
	}

	private async pruneInvalidTokens(
		dispositivos: Array<{ id: string; token: string }>,
		responses: Array<{ success: boolean; error?: { code?: string } }>,
	) {
		const invalidCodes = new Set([
			'messaging/invalid-registration-token',
			'messaging/registration-token-not-registered',
		]);

		const toDelete: string[] = [];
		responses.forEach((res, index) => {
			const code = res.error?.code;
			if (!res.success && code && invalidCodes.has(code)) {
				toDelete.push(dispositivos[index].token);
			}
		});

		if (toDelete.length === 0) return;

		await this.prisma.dispositivoFcm.deleteMany({
			where: { token: { in: toDelete } },
		});
		this.logger.log(`[push] Tokens inválidos eliminados: ${toDelete.length}`);
	}
}
