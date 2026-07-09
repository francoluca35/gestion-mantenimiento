enum PlantaClipboardMode { copiar, mover }

class PlantaClipboard {
	const PlantaClipboard({
		required this.equipoId,
		required this.nombre,
		required this.codigo,
		required this.mode,
	});

	final String equipoId;
	final String nombre;
	final String codigo;
	final PlantaClipboardMode mode;

	bool get isMove => mode == PlantaClipboardMode.mover;
}

enum PlantaDragKind { equipo, ubicacion }

class PlantaDragPayload {
	const PlantaDragPayload({
		required this.kind,
		required this.id,
		required this.label,
	});

	final PlantaDragKind kind;
	final String id;
	final String label;
}
