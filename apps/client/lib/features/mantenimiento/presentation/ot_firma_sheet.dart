import 'package:flutter/material.dart';

import '../../../components/signature_pad.dart';
import '../../../core/theme/app_colors.dart';

/// Captura firma del técnico (táctil o mouse) antes de cerrar la OT.
class OtFirmaSheet {
	const OtFirmaSheet._();

	static Future<String?> show(BuildContext context) {
		final wide = MediaQuery.sizeOf(context).width >= 600;
		final sheetKey = UniqueKey();

		if (wide) {
			return showDialog<String>(
				context: context,
				barrierDismissible: false,
				builder: (context) => Dialog(
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 520),
						child: _FirmaBody(key: sheetKey),
					),
				),
			);
		}

		return showModalBottomSheet<String>(
			context: context,
			isScrollControlled: true,
			useSafeArea: true,
			isDismissible: false,
			enableDrag: false,
			builder: (context) => Padding(
				padding: const EdgeInsets.only(top: 8),
				child: _FirmaBody(key: sheetKey),
			),
		);
	}
}

class _FirmaBody extends StatefulWidget {
	const _FirmaBody({super.key});

	@override
	State<_FirmaBody> createState() => _FirmaBodyState();
}

class _FirmaBodyState extends State<_FirmaBody> {
	final _padKey = GlobalKey<SignaturePadState>();
	bool _saving = false;

	Future<void> _confirmar() async {
		final pad = _padKey.currentState;
		if (pad == null || pad.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Dibujá tu firma antes de confirmar')),
			);
			return;
		}

		setState(() => _saving = true);
		final firma = await pad.exportBase64();
		if (!mounted) return;

		if (firma == null) {
			setState(() => _saving = false);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No se pudo guardar la firma')),
			);
			return;
		}

		Navigator.of(context).pop(firma);
	}

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Padding(
			padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Row(
						children: [
							Expanded(
								child: Text(
									'Firmar orden de trabajo',
									style: Theme.of(context).textTheme.titleLarge?.copyWith(
												fontWeight: FontWeight.w700,
											),
								),
							),
							IconButton(
								onPressed: _saving ? null : () => Navigator.of(context).pop(),
								icon: const Icon(Icons.close_rounded),
							),
						],
					),
					const SizedBox(height: 4),
					Text(
						'Dibujá con el dedo o el mouse en el recuadro',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									color: scheme.onSurfaceVariant,
								),
					),
					const SizedBox(height: 16),
					DecoratedBox(
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(12),
							border: Border.all(color: scheme.outlineVariant, width: 2),
						),
						child: SizedBox(
							height: 200,
							width: double.infinity,
							child: SignaturePad(
								key: _padKey,
								backgroundColor: scheme.brightness == Brightness.dark
										? const Color(0xFF2A2A2A)
										: Colors.white,
								strokeColor: scheme.brightness == Brightness.dark
										? Colors.white
										: AppColors.ink,
							),
						),
					),
					const SizedBox(height: 12),
					Row(
						children: [
							TextButton.icon(
								onPressed: _saving ? null : () => _padKey.currentState?.clear(),
								icon: const Icon(Icons.refresh_rounded),
								label: const Text('Borrar'),
							),
							const Spacer(),
							FilledButton.icon(
								style: FilledButton.styleFrom(
									backgroundColor: AppColors.success,
									padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
								),
								onPressed: _saving ? null : _confirmar,
								icon: _saving
										? const SizedBox(
												width: 18,
												height: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Icon(Icons.check_rounded),
								label: Text(_saving ? 'Guardando…' : 'Confirmar firma'),
							),
						],
					),
				],
			),
		);
	}
}
