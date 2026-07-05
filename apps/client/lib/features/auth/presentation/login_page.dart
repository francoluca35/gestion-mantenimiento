import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
			context.go('/home');
		}
	}

	@override
	Widget build(BuildContext context) {
		final auth = ref.watch(authControllerProvider);

		return Scaffold(
			body: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 420),
					child: Card(
						margin: const EdgeInsets.all(24),
						child: Padding(
							padding: const EdgeInsets.all(24),
							child: Form(
								key: _formKey,
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										Text(
											'Gestión de Mantenimiento',
											style: Theme.of(context).textTheme.headlineSmall?.copyWith(
														fontWeight: FontWeight.bold,
													),
										),
										const SizedBox(height: 8),
										Text(
											'Ingresá con tu usuario Sika',
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(
														color: Colors.grey.shade600,
													),
										),
										const SizedBox(height: 24),
										TextFormField(
											controller: _userController,
											textInputAction: TextInputAction.next,
											decoration: const InputDecoration(
												labelText: 'Usuario',
												prefixIcon: Icon(Icons.person_outline),
											),
											validator: (value) {
												if (value == null || value.trim().isEmpty) {
													return 'Ingresá el usuario';
												}
												return null;
											},
										),
										const SizedBox(height: 12),
										TextFormField(
											controller: _passwordController,
											obscureText: true,
											onFieldSubmitted: (_) => _submit(),
											decoration: const InputDecoration(
												labelText: 'Clave',
												prefixIcon: Icon(Icons.lock_outline),
											),
											validator: (value) {
												if (value == null || value.isEmpty) {
													return 'Ingresá la clave';
												}
												return null;
											},
										),
										if (auth.error != null) ...[
											const SizedBox(height: 12),
											Text(
												auth.error!,
												style: TextStyle(
													color: Theme.of(context).colorScheme.error,
												),
											),
										],
										const SizedBox(height: 24),
										FilledButton(
											onPressed: auth.loading ? null : _submit,
											child: auth.loading
													? const SizedBox(
															height: 20,
															width: 20,
															child: CircularProgressIndicator(strokeWidth: 2),
														)
													: const Text('Ingresar'),
										),
										const SizedBox(height: 16),
										Text(
											'Demo: admin / tecnico / panolero\nClave: Sika123!',
											textAlign: TextAlign.center,
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Colors.grey.shade600,
													),
										),
									],
								),
							),
						),
					),
				),
			),
		);
	}
}
