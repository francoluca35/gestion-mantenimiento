import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_logo.dart';
import '../../../components/sika_ui.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
	const LoginPage({super.key});

	@override
	ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
	final _userController = TextEditingController();
	final _passwordController = TextEditingController();
	final _formKey = GlobalKey<FormState>();

	@override
	void dispose() {
		_userController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;

		final ok = await ref.read(authControllerProvider.notifier).login(
					nombreUsuario: _userController.text,
					clave: _passwordController.text,
				);

		if (!mounted) return;
		if (ok) {
			final user = ref.read(authControllerProvider).session?.usuario;
			context.go(
				user?.esTecnico == true
						? '/mis-ot'
						: user?.esPanolero == true
								? '/panol'
								: '/home',
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final auth = ref.watch(authControllerProvider);

		return Scaffold(
			backgroundColor: AppColors.backgroundDark,
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						padding: const EdgeInsets.all(24),
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 420),
							child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: double.infinity,
									padding: const EdgeInsets.symmetric(
										vertical: 28,
										horizontal: 16,
									),
									decoration: BoxDecoration(
										color: AppColors.black,
										borderRadius: BorderRadius.circular(20),
										border: Border.all(
											color: AppColors.brandPurple.withValues(alpha: 0.45),
										),
									),
									child: const Center(
										child: SikaLogo(size: 120, compact: true),
									),
								),
								const SizedBox(height: 20),
								SikaCard(
									padding: const EdgeInsets.all(28),
									child: Form(
										key: _formKey,
										child: Column(
											mainAxisSize: MainAxisSize.min,
											crossAxisAlignment: CrossAxisAlignment.stretch,
											children: [
												const Text(
													'GestionMantenimiento',
													style: TextStyle(
														fontWeight: FontWeight.w800,
														fontSize: 22,
														color: Colors.white,
													),
												),
												const SizedBox(height: 8),
												const Text(
													'Ingresá con tu usuario Sika',
													style: TextStyle(color: AppColors.mutedText),
												),
												const SizedBox(height: 24),
												TextFormField(
													controller: _userController,
													style: const TextStyle(color: Colors.white),
													decoration: const InputDecoration(
														labelText: 'Usuario',
														prefixIcon: Icon(Icons.person_outline_rounded),
													),
													textInputAction: TextInputAction.next,
													autofillHints: const [AutofillHints.username],
													validator: (v) =>
															(v == null || v.trim().isEmpty) ? 'Requerido' : null,
												),
												const SizedBox(height: 16),
												TextFormField(
													controller: _passwordController,
													style: const TextStyle(color: Colors.white),
													decoration: const InputDecoration(
														labelText: 'Contraseña',
														prefixIcon: Icon(Icons.lock_outline_rounded),
													),
													obscureText: true,
													autofillHints: const [AutofillHints.password],
													onFieldSubmitted: (_) => _submit(),
													validator: (v) =>
															(v == null || v.isEmpty) ? 'Requerido' : null,
												),
												if (auth.error != null) ...[
													const SizedBox(height: 16),
													Text(
														auth.error!,
														style: const TextStyle(color: AppColors.danger),
													),
												],
												const SizedBox(height: 24),
												FilledButton(
													onPressed: auth.loading ? null : _submit,
													style: FilledButton.styleFrom(
														backgroundColor: AppColors.brandPurple,
														foregroundColor: AppColors.onPrimary,
														padding: const EdgeInsets.symmetric(vertical: 16),
													),
													child: auth.loading
															? const SizedBox(
																	height: 22,
																	width: 22,
																	child: CircularProgressIndicator(
																		strokeWidth: 2,
																		color: AppColors.onPrimary,
																	),
																)
															: const Text(
																	'Ingresar',
																	style: TextStyle(fontWeight: FontWeight.w700),
																),
												),
											const SizedBox(height: 12),
												TextButton(
													onPressed: auth.loading
															? null
															: () => _abrirRecuperarClave(context),
													child: const Text('¿Olvidaste tu clave?'),
												),
											],
										),
									),
								),
							],
						),
					),
				),
			),
			),
		);
	}

	Future<void> _abrirRecuperarClave(BuildContext context) async {
		final userCtrl = TextEditingController(text: _userController.text);
		final codigoCtrl = TextEditingController();
		final claveCtrl = TextEditingController();
		String? codigoDemo;
		String? mensaje;
		var paso = 1;
		var busy = false;

		await showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (context, setLocal) {
						Future<void> pedirCodigo() async {
							if (userCtrl.text.trim().isEmpty) return;
							setLocal(() => busy = true);
							try {
								final api = ApiClient();
								final res = await api.postJson(
									'auth/recuperar',
									{'nombreUsuario': userCtrl.text.trim()},
									auth: false,
								);
								codigoDemo = res['codigoDemo']?.toString();
								mensaje = res['mensaje']?.toString();
								if (codigoDemo != null) {
									codigoCtrl.text = codigoDemo!;
								}
								setLocal(() => paso = 2);
							} catch (e) {
								mensaje = e.toString();
								setLocal(() {});
							} finally {
								setLocal(() => busy = false);
							}
						}

						Future<void> restablecer() async {
							setLocal(() => busy = true);
							try {
								final api = ApiClient();
								await api.postJson(
									'auth/restablecer',
									{
										'nombreUsuario': userCtrl.text.trim(),
										'codigo': codigoCtrl.text.trim(),
										'claveNueva': claveCtrl.text,
									},
									auth: false,
								);
								if (dialogContext.mounted) {
									Navigator.of(dialogContext).pop();
								}
								if (!mounted) return;
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(
										content: Text('Clave actualizada. Ingresá con la nueva.'),
									),
								);
							} catch (e) {
								mensaje = e.toString();
								setLocal(() {});
							} finally {
								setLocal(() => busy = false);
							}
						}

						return AlertDialog(
							title: Text(paso == 1 ? 'Recuperar clave' : 'Nueva clave'),
							content: SizedBox(
								width: 360,
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										if (paso == 1) ...[
											TextField(
												controller: userCtrl,
												decoration: const InputDecoration(
													labelText: 'Usuario',
												),
											),
										] else ...[
											TextField(
												controller: codigoCtrl,
												decoration: const InputDecoration(
													labelText: 'Código',
												),
											),
											const SizedBox(height: 12),
											TextField(
												controller: claveCtrl,
												obscureText: true,
												decoration: const InputDecoration(
													labelText: 'Nueva clave',
												),
											),
											if (codigoDemo != null) ...[
												const SizedBox(height: 8),
												Text(
													'Código demo: $codigoDemo',
													style: const TextStyle(
														color: AppColors.brandGreen,
														fontWeight: FontWeight.w700,
													),
												),
											],
										],
										if (mensaje != null) ...[
											const SizedBox(height: 12),
											Text(
												mensaje!,
												style: const TextStyle(fontSize: 13),
											),
										],
									],
								),
							),
							actions: [
								TextButton(
									onPressed: busy
											? null
											: () => Navigator.of(dialogContext).pop(),
									child: const Text('Cancelar'),
								),
								FilledButton(
									onPressed: busy
											? null
											: () => paso == 1 ? pedirCodigo() : restablecer(),
									child: Text(paso == 1 ? 'Enviar código' : 'Guardar'),
								),
							],
						);
					},
				);
			},
		);

		userCtrl.dispose();
		codigoCtrl.dispose();
		claveCtrl.dispose();
	}
}
