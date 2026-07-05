export const ESTADOS_OT = [
	'necesaria_de_emitir',
	'pendiente',
	'pendiente_pañol',
	'en_ejecucion',
	'realizada',
	'anulada',
] as const;

export type EstadoOt = (typeof ESTADOS_OT)[number];

export const TIPOS_OT = [
	'preventivo',
	'predictivo',
	'correctivo',
	'mejora',
] as const;

export type TipoOt = (typeof TIPOS_OT)[number];
