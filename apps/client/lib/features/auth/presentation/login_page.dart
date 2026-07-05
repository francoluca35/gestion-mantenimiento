import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
	const LoginPage({super.key});

	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
	final _userController = TextEditingController();
	final _passwordController = TextEditingController();
	bool _loading = false;

	@override
	void dispose() {
		_userController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		setState(() => _loading = true);
		await Future<void>.delayed(const Duration(milliseconds: 400));
		if (!mounted) return;
		setState(() => _loading = false);
		context.go('/home');
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 420),
					child: Card(
						margin: const EdgeInsets.all(24),
						child: Padding(
							padding: const EdgeInsets.all(24),
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
									TextField(
										controller: _userController,
										decoration: const InputDecoration(
											labelText: 'Usuario',
											prefixIcon: Icon(Icons.person_outline),
										),
									),
									const SizedBox(height: 12),
									TextField(
										controller: _passwordController,
										obscureText: true,
										decoration: const InputDecoration(
											labelText: 'Clave',
											prefixIcon: Icon(Icons.lock_outline),
										),
									),
									const SizedBox(height: 24),
									FilledButton(
										onPressed: _loading ? null : _submit,
										child: _loading
												? const SizedBox(
														height: 20,
														width: 20,
														child: CircularProgressIndicator(strokeWidth: 2),
													)
												: const Text('Ingresar'),
									),
								],
							),
						),
					),
				),
			),
		);
	}
}
