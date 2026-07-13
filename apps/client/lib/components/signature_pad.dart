import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Lienzo de firma con puntero (mouse / táctil / web).
class SignaturePad extends StatefulWidget {
	const SignaturePad({
		super.key,
		this.strokeColor,
		this.strokeWidth = 2.5,
		this.backgroundColor,
	});

	final Color? strokeColor;
	final double strokeWidth;
	final Color? backgroundColor;

	@override
	State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
	final List<List<Offset>> _strokes = [];
	int? _activePointer;

	bool get isEmpty =>
			_strokes.isEmpty || _strokes.every((stroke) => stroke.isEmpty);

	void clear() => setState(() {
				_strokes.clear();
				_activePointer = null;
			});

	/// Exporta PNG para documentos: trazo negro sobre fondo transparente
	/// (independiente del color del pad en pantalla / tema oscuro).
	Future<String?> exportBase64({
		Color exportStrokeColor = const Color(0xFF000000),
		Color exportBackgroundColor = const Color(0x00000000),
	}) async {
		if (isEmpty) return null;

		final box = context.findRenderObject() as RenderBox?;
		if (box == null || !box.hasSize) return null;

		final width = box.size.width;
		final height = box.size.height;
		if (width <= 0 || height <= 0) return null;

		final recorder = ui.PictureRecorder();
		final canvas = Canvas(recorder, Offset.zero & Size(width, height));
		_SignaturePainter(
			strokes: _strokes,
			strokeColor: exportStrokeColor,
			strokeWidth: widget.strokeWidth,
			backgroundColor: exportBackgroundColor,
		).paint(canvas, Size(width, height));

		final picture = recorder.endRecording();
		final image = await picture.toImage(width.ceil(), height.ceil());
		final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
		if (byteData == null) return null;

		return 'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
	}

	void _startStroke(Offset position) {
		setState(() => _strokes.add([position]));
	}

	void _extendStroke(Offset position) {
		if (_strokes.isEmpty) return;
		final stroke = _strokes.last;
		if (stroke.isNotEmpty && stroke.last == position) return;
		setState(() => stroke.add(position));
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final strokeColor = widget.strokeColor ?? scheme.onSurface;
		final backgroundColor =
				widget.backgroundColor ?? scheme.surfaceContainerHighest;

		return Listener(
			behavior: HitTestBehavior.opaque,
			onPointerDown: (event) {
				_activePointer = event.pointer;
				_startStroke(event.localPosition);
			},
			onPointerMove: (event) {
				if (_activePointer != event.pointer) return;
				_extendStroke(event.localPosition);
			},
			onPointerUp: (event) {
				if (_activePointer == event.pointer) _activePointer = null;
			},
			onPointerCancel: (event) {
				if (_activePointer == event.pointer) _activePointer = null;
			},
			child: ClipRRect(
				borderRadius: BorderRadius.circular(12),
				child: CustomPaint(
					painter: _SignaturePainter(
						strokes: _strokes,
						strokeColor: strokeColor,
						strokeWidth: widget.strokeWidth,
						backgroundColor: backgroundColor,
					),
					child: const SizedBox.expand(),
				),
			),
		);
	}
}

class _SignaturePainter extends CustomPainter {
	const _SignaturePainter({
		required this.strokes,
		required this.strokeColor,
		required this.strokeWidth,
		required this.backgroundColor,
	});

	final List<List<Offset>> strokes;
	final Color strokeColor;
	final double strokeWidth;
	final Color backgroundColor;

	@override
	void paint(Canvas canvas, Size size) {
		if (backgroundColor.a > 0) {
			canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
		}

		final paint = Paint()
				..color = strokeColor
				..strokeWidth = strokeWidth
				..strokeCap = StrokeCap.round
				..strokeJoin = StrokeJoin.round
				..style = PaintingStyle.stroke;

		for (final stroke in strokes) {
			if (stroke.isEmpty) continue;
			if (stroke.length == 1) {
				canvas.drawCircle(stroke.first, strokeWidth / 2, paint);
				continue;
			}
			final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
			for (var i = 1; i < stroke.length; i++) {
				path.lineTo(stroke[i].dx, stroke[i].dy);
			}
			canvas.drawPath(path, paint);
		}
	}

	@override
	bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
		return oldDelegate.strokes != strokes ||
				oldDelegate.strokeColor != strokeColor ||
				oldDelegate.strokeWidth != strokeWidth ||
				oldDelegate.backgroundColor != backgroundColor;
	}
}
