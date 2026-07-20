import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_logo.dart';
import '../../../components/sika_ui.dart';
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
			body: Center(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(24),
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 420),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									width: double.infinity,
									padding: const EdgeInsets.symmetric(vertical: 28),
									decoration: BoxDecoration(
										color: AppColors.brandYellow,
										borderRadius: BorderRadius.circular(20),
									),
									child: const Center(
										child: SikaLogo(size: 52, showTagline: true),
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
													'Gestión de Mantenimiento',
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
														backgroundColor: AppColors.brandYellow,
														foregroundColor: AppColors.ink,
														padding: const EdgeInsets.symmetric(vertical: 16),
													),
													child: auth.loading
															? const SizedBox(
																	height: 22,
																	width: 22,
																	child: CircularProgressIndicator(
																		strokeWidth: 2,
																		color: AppColors.ink,
																	),
																)
															: const Text(
																	'Ingresar',
																	style: TextStyle(fontWeight: FontWeight.w700),
																),
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
		);
	}
}
