import {
	EstadoOt,
	EstadoPedidoStock,
	EstadoSolicitudMaterial,
} from '@prisma/client';

type PanolGateTx = {
	ordenTrabajo: {
		findUnique: (args: {
			where: { id: string };
			select: { id: true; estado: true };
		}) => Promise<{ id: string; estado: string } | null>;
		update: (args: {
			where: { id: string };
			data: { estado: EstadoOt };
		}) => Promise<unknown>;
	};
	solicitudMaterial: {
		count: (args: {
			where: { otId: string; estado: EstadoSolicitudMaterial };
		}) => Promise<number>;
	};
	pedidoStock: {
		count: (args: {
			where: {
				otId: string;
				estado: { in: EstadoPedidoStock[] };
			};
		}) => Promise<number>;
	};
	otEstadoHistorial: {
		create: (args: {
			data: {
				otId: string;
				estado: EstadoOt;
				usuarioId: string;
				comentario: string;
			};
		}) => Promise<unknown>;
	};
};

/**
 * Si la OT espera pañol y ya no hay solicitudes ni pedidos pendientes,
 * vuelve a `pendiente` para que el técnico pueda iniciar.
 */
export async function tryLiberarOtTrasPanol(
	tx: PanolGateTx,
	otId: string,
	usuarioId: string,
	comentario: string,
): Promise<boolean> {
	const ot = await tx.ordenTrabajo.findUnique({
		where: { id: otId },
		select: { id: true, estado: true },
	});
	if (!ot || ot.estado !== EstadoOt.pendiente_panol) {
		return false;
	}

	const [solPend, pedPend] = await Promise.all([
		tx.solicitudMaterial.count({
			where: { otId, estado: EstadoSolicitudMaterial.pendiente },
		}),
		tx.pedidoStock.count({
			where: {
				otId,
				estado: {
					in: [EstadoPedidoStock.pendiente, EstadoPedidoStock.en_proceso],
				},
			},
		}),
	]);

	if (solPend > 0 || pedPend > 0) {
		return false;
	}

	await tx.ordenTrabajo.update({
		where: { id: otId },
		data: { estado: EstadoOt.pendiente },
	});
	await tx.otEstadoHistorial.create({
		data: {
			otId,
			estado: EstadoOt.pendiente,
			usuarioId,
			comentario,
		},
	});
	return true;
}
