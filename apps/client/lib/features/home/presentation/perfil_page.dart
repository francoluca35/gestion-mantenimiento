import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../components/sika_ui.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class PerfilPage extends ConsumerStatefulWidget {
	const PerfilPage({super.key});

	@override
	ConsumerState<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends ConsumerState<PerfilPage> {
	List<Map<String, dynamic>> _sesiones = [];
	bool _loadingSesiones = true;
	String? _sesionesError;
	late final TextEditingController _apiUrlCtrl;
	bool _savingApiUrl = false;

	@override
	void initState() {
		super.initState();
		_apiUrlCtrl = TextEditingController(text: AppConfig.apiBaseUrl);
		_cargarSesiones();
	}

	@override
	void dispose() {
		_apiUrlCtrl.dispose();
		super.dispose();
	}

	Future<void> _guardarApiUrl() async {
		final raw = _apiUrlCtrl.text.trim();
		if (raw.isNotEmpty) {
			final uri = Uri.tryParse(raw);
			if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('URL inválida. Ej: http://192.168.1.10:3000/v1')),
				);
				return;
			}
		}

		setState(() => _savingApiUrl = true);
		try {
			final prefs = ref.read(sharedPreferencesProvider);
			final effective = await AppConfig.setOverride(
				prefs,
				raw.isEmpty ? null : raw,
			);
			_apiUrlCtrl.text = effective;
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(
						'API: $effective\nCerrá sesión e ingresá de nuevo para aplicar.',
					),
				),
			);
			await ref.read(authControllerProvider.notifier).logout();
			if (mounted) context.go('/login');
		} finally {
			if (mounted) setState(() => _savingApiUrl = false);
		}
	}

	Future<void> _cargarSesiones() async {
		setState(() {
			_loadingSesiones = true;
			_sesionesError = null;
		});

		try {
			final data = await ref.read(apiClientProvider).getList('auth/sesiones');
			if (!mounted) return;
			setState(() {
				_sesiones = data.cast<Map<String, dynamic>>();
				_loadingSesiones = false;
			});
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_sesionesError = error.toString();
				_loadingSesiones = false;
			});
		}
	}

	Future<void> _cambiarClave() async {
		final actualCtrl = TextEditingController();
		final nuevaCtrl = TextEditingController();
		final confirmCtrl = TextEditingController();
		final formKey = GlobalKey<FormState>();
		var submitting = false;
		String? error;

		final ok = await showDialog<bool>(
			context: context,
			builder: (ctx) => StatefulBuilder(
				builder: (ctx, setDialog) {
					return AlertDialog(
						title: const Text('Cambiar clave'),
						content: Form(
							key: formKey,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									TextFormField(
										controller: actualCtrl,
										obscureText: true,
										decoration: const InputDecoration(
											labelText: 'Clave actual',
										),
										validator: (v) =>
												(v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
									),
									const SizedBox(height: 12),
									TextFormField(
										controller: nuevaCtrl,
										obscureText: true,
										decoration: const InputDecoration(
											labelText: 'Clave nueva',
										),
										validator: (v) =>
												(v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
									),
									const SizedBox(height: 12),
									TextFormField(
										controller: confirmCtrl,
										obscureText: true,
										decoration: const InputDecoration(
											labelText: 'Confirmar clave nueva',
										),
										validator: (v) => v != nuevaCtrl.text ? 'No coincide' : null,
									),
									if (error != null) ...[
										const SizedBox(height: 12),
										Text(error!, style: const TextStyle(color: AppColors.danger)),
									],
								],
							),
						),
						actions: [
							TextButton(
								onPressed: submitting ? null : () => Navigator.pop(ctx, false),
								child: const Text('Cancelar'),
							),
							FilledButton(
								onPressed: submitting
										? null
										: () async {
											if (!formKey.currentState!.validate()) return;
											setDialog(() {
												submitting = true;
												error = null;
											});
											try {
												await ref.read(apiClientProvider).patchJson('auth/clave', {
													'claveActual': actualCtrl.text,
													'claveNueva': nuevaCtrl.text,
												});
												if (ctx.mounted) Navigator.pop(ctx, true);
											} catch (e) {
												setDialog(() {
													error = e.toString();
													submitting = false;
												});
											}
										},
								child: submitting
										? const SizedBox(
												width: 18,
												height: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Text('Guardar'),
							),
						],
					);
				},
			),
		);

		actualCtrl.dispose();
		nuevaCtrl.dispose();
		confirmCtrl.dispose();

		if (ok == true && mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text(
						'Clave actualizada. Deberás iniciar sesión nuevamente.',
					),
				),
			);
			await ref.read(authControllerProvider.notifier).logout();
			if (mounted) context.go('/login');
		}
	}

	Future<void> _revocarSesiones() async {
		final confirm = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Cerrar otras sesiones'),
				content: const Text(
					'Se cerrarán todas las sesiones activas, incluida la actual. '
					'Deberás volver a iniciar sesión.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx, false),
						child: const Text('Cancelar'),
					),
					FilledButton(
						onPressed: () => Navigator.pop(ctx, true),
						child: const Text('Cerrar todas'),
					),
				],
			),
		);

		if (confirm != true) return;

		try {
			await ref.read(apiClientProvider).postJson('auth/sesiones/revocar-todas', {});
			if (!mounted) return;
			await ref.read(authControllerProvider.notifier).logout();
			if (mounted) context.go('/login');
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final user = ref.watch(authControllerProvider).session?.usuario;
		final esTecnico = user?.esTecnico == true;
		final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

		final content = ListView(
			padding: const EdgeInsets.all(20),
			children: [
				SikaCard(
					padding: const EdgeInsets.all(24),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									CircleAvatar(
										radius: 28,
										backgroundColor: AppColors.primary.withValues(alpha: 0.12),
										child: Text(
											(user?.nombreUsuario.isNotEmpty == true)
													? user!.nombreUsuario[0].toUpperCase()
													: 'U',
											style: const TextStyle(
												color: AppColors.primary,
												fontWeight: FontWeight.w700,
												fontSize: 20,
											),
										),
									),
									const SizedBox(width: 16),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													user?.nombreUsuario ?? '',
													style: Theme.of(context).textTheme.titleLarge?.copyWith(
																fontWeight: FontWeight.w700,
															),
												),
												Text(
													user?.perfilNombre ??
															(user?.esAdministrador == true
																	? 'Administrador'
																	: 'Sin perfil'),
												),
											],
										),
									),
								],
							),
							const SizedBox(height: 20),
							Wrap(
								spacing: 12,
								runSpacing: 12,
								children: [
									_InfoChip(
										label: 'Planta',
										value: user?.sucursalNombre ?? 'Sin planta',
									),
									_InfoChip(
										label: 'Derechos',
										value: '${user?.derechos.length ?? 0}',
									),
									_InfoChip(
										label: 'Admin',
										value: user?.esAdministrador == true ? 'Sí' : 'No',
									),
								],
							),
						],
					),
				),
				const SizedBox(height: 16),
				SikaCard(
					padding: const EdgeInsets.all(20),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								'Seguridad',
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											fontWeight: FontWeight.w700,
										),
							),
							const SizedBox(height: 12),
							SizedBox(
								width: double.infinity,
								child: OutlinedButton.icon(
									onPressed: _cambiarClave,
									icon: const Icon(Icons.lock_outline_rounded),
									label: const Text('Cambiar clave'),
								),
							),
						],
					),
				),
				const SizedBox(height: 16),
				SikaCard(
					padding: const EdgeInsets.all(20),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Expanded(
										child: Text(
											'Sesiones recientes',
											style: Theme.of(context).textTheme.titleMedium?.copyWith(
														fontWeight: FontWeight.w700,
													),
										),
									),
									TextButton(
										onPressed: _loadingSesiones ? null : _cargarSesiones,
										child: const Text('Actualizar'),
									),
								],
							),
							const SizedBox(height: 8),
							if (_loadingSesiones)
								const Center(child: CircularProgressIndicator())
							else if (_sesionesError != null)
								Text(_sesionesError!, style: const TextStyle(color: AppColors.danger))
							else if (_sesiones.isEmpty)
								const Text('Sin sesiones registradas')
							else
								..._sesiones.map((s) {
									final created = DateTime.tryParse(s['createdAt'] as String? ?? '');
									final revocada = s['revocada'] == true;
									return Padding(
										padding: const EdgeInsets.only(bottom: 8),
										child: Row(
											children: [
												Icon(
													revocada
															? Icons.link_off_rounded
															: Icons.link_rounded,
													size: 18,
													color: revocada ? AppColors.mutedText : AppColors.accent,
												),
												const SizedBox(width: 8),
												Expanded(
													child: Text(
														created != null
																? dateFmt.format(created.toLocal())
																: 'Sesión',
														style: TextStyle(
															color: revocada ? AppColors.mutedText : null,
														),
													),
												),
												if (revocada)
													const Text(
														'Cerrada',
														style: TextStyle(
															fontSize: 12,
															color: AppColors.mutedText,
														),
													)
												else
													const Text(
														'Activa',
														style: TextStyle(
															fontSize: 12,
															color: AppColors.accent,
															fontWeight: FontWeight.w600,
														),
													),
											],
										),
									);
								}),
							const SizedBox(height: 8),
							SizedBox(
								width: double.infinity,
								child: FilledButton.tonalIcon(
									onPressed: _revocarSesiones,
									icon: const Icon(Icons.phonelink_erase_rounded),
									label: const Text('Cerrar todas las sesiones'),
								),
							),
						],
					),
				),
				if (!kIsWeb) ...[
					const SizedBox(height: 16),
					SikaCard(
						padding: const EdgeInsets.all(20),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Servidor API',
									style: Theme.of(context).textTheme.titleMedium?.copyWith(
												fontWeight: FontWeight.w700,
											),
								),
								const SizedBox(height: 8),
								Text(
									'Misma Wi‑Fi que la PC, hotspot, o USB con adb reverse '
									'(http://127.0.0.1:3000/v1). Vacío = valor de compilación.',
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: AppColors.mutedText,
											),
								),
								const SizedBox(height: 12),
								TextField(
									controller: _apiUrlCtrl,
									keyboardType: TextInputType.url,
									autocorrect: false,
									decoration: const InputDecoration(
										labelText: 'URL API',
										hintText: 'http://192.168.x.x:3000/v1',
										border: OutlineInputBorder(),
									),
								),
								if (AppConfig.hasOverride) ...[
									const SizedBox(height: 8),
									Text(
										'Override activo (compile: ${AppConfig.compileTimeApiBaseUrl})',
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: AppColors.mutedText,
												),
									),
								],
								const SizedBox(height: 12),
								SizedBox(
									width: double.infinity,
									child: FilledButton.tonalIcon(
										onPressed: _savingApiUrl ? null : _guardarApiUrl,
										icon: _savingApiUrl
												? const SizedBox(
														width: 16,
														height: 16,
														child: CircularProgressIndicator(strokeWidth: 2),
													)
												: const Icon(Icons.save_outlined),
										label: Text(_savingApiUrl ? 'Guardando…' : 'Guardar URL'),
									),
								),
							],
						),
					),
				],
				const SizedBox(height: 16),
				SizedBox(
					width: double.infinity,
					child: FilledButton.tonalIcon(
						onPressed: () async {
							await ref.read(authControllerProvider.notifier).logout();
							if (context.mounted) context.go('/login');
						},
						icon: const Icon(Icons.logout_rounded),
						label: const Text('Cerrar sesión'),
					),
				),
			],
		);

		if (!esTecnico) return content;

		return Column(
			children: [
				Material(
					color: Theme.of(context).colorScheme.surface,
					child: SafeArea(
						bottom: false,
						child: SizedBox(
							height: 56,
							child: Row(
								children: [
									IconButton(
										onPressed: () => context.go('/mis-ot'),
										icon: const Icon(Icons.arrow_back_rounded),
									),
									Text(
										'Perfil',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.w700,
												),
									),
								],
							),
						),
					),
				),
				Expanded(child: content),
			],
		);
	}
}

class _InfoChip extends StatelessWidget {
	const _InfoChip({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
				borderRadius: BorderRadius.circular(12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(label, style: Theme.of(context).textTheme.bodySmall),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
				],
			),
		);
	}
}
