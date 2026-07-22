import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';

class EmitirOtPageShell extends StatelessWidget {
	const EmitirOtPageShell({
		super.key,
		required this.titulo,
		required this.subtitulo,
		required this.gradient,
		required this.icon,
		required this.child,
		this.loading = false,
	});

	final String titulo;
	final String subtitulo;
	final List<Color> gradient;
	final IconData icon;
	final Widget child;
	final bool loading;

	@override
	Widget build(BuildContext context) {
		final pad = responsivePagePadding(context);
		return ListView(
			padding: pad,
			children: [
				Container(
					padding: pad,
					decoration: BoxDecoration(
						gradient: LinearGradient(
							colors: gradient,
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
						borderRadius: BorderRadius.circular(20),
					),
					child: Row(
						children: [
							Container(
								width: 52,
								height: 52,
								decoration: BoxDecoration(
									color: Colors.white.withValues(alpha: 0.18),
									borderRadius: BorderRadius.circular(14),
								),
								child: Icon(icon, color: Colors.white, size: 28),
							),
							const SizedBox(width: 16),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											titulo,
											style: Theme.of(context).textTheme.titleLarge?.copyWith(
														color: Colors.white,
														fontWeight: FontWeight.w800,
													),
										),
										const SizedBox(height: 4),
										Text(
											subtitulo,
											style: TextStyle(
												color: Colors.white.withValues(alpha: 0.85),
												fontSize: 13,
											),
										),
									],
								),
							),
						],
					),
				),
				const SizedBox(height: 20),
				if (loading)
					const Center(
						child: Padding(
							padding: EdgeInsets.all(40),
							child: CircularProgressIndicator(),
						),
					)
				else
					Material(
						color: Theme.of(context).colorScheme.surface,
						borderRadius: BorderRadius.circular(20),
						child: Container(
							padding: pad,
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(20),
								border: Border.all(
									color: Theme.of(context)
											.colorScheme
											.outlineVariant
											.withValues(alpha: 0.35),
								),
							),
							child: child,
						),
					),
			],
		);
	}
}

class EmitirOtFormActions extends StatelessWidget {
	const EmitirOtFormActions({
		super.key,
		required this.onCancel,
		required this.onSubmit,
		required this.submitLabel,
		this.submitting = false,
		this.accentColor = AppColors.accent,
	});

	final VoidCallback onCancel;
	final VoidCallback onSubmit;
	final String submitLabel;
	final bool submitting;
	final Color accentColor;

	@override
	Widget build(BuildContext context) {
		final cancel = OutlinedButton(
			onPressed: submitting ? null : onCancel,
			child: const Text('Cancelar'),
		);
		final submit = FilledButton.icon(
			style: FilledButton.styleFrom(backgroundColor: accentColor),
			onPressed: submitting ? null : onSubmit,
			icon: submitting
					? const SizedBox(
							width: 18,
							height: 18,
							child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
						)
					: const Icon(Icons.send_rounded, size: 18),
			label: Text(submitLabel),
		);

		if (isCompactLayout(context)) {
			return Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					submit,
					const SizedBox(height: 10),
					cancel,
				],
			);
		}

		return Row(
			children: [
				cancel,
				const Spacer(),
				submit,
			],
		);
	}
}

void navegarTrasEmitir(BuildContext context, Map<String, dynamic> ot) {
	ScaffoldMessenger.of(context).showSnackBar(
		SnackBar(content: Text('OT #${ot['numero']} emitida correctamente')),
	);
	context.go('/ot');
}
