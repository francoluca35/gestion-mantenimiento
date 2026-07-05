import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/adaptive_scaffold.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_controller.dart';

class HomePage extends ConsumerStatefulWidget {
	const HomePage({super.key});

	@override
	ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
	int _selectedIndex = 0;

	List<NavigationDestination> _destinations(bool canConfig) {
		return [
			const NavigationDestination(
				icon: Icon(Icons.home_outlined),
				selectedIcon: Icon(Icons.home),
				label: 'Inicio',
			),
			const NavigationDestination(
				icon: Icon(Icons.assignment_outlined),
				selectedIcon: Icon(Icons.assignment),
				label: 'Mis OT',
			),
			if (canConfig)
				const NavigationDestination(
					icon: Icon(Icons.settings_outlined),
					selectedIcon: Icon(Icons.settings),
					label: 'Config',
				),
			const NavigationDestination(
				icon: Icon(Icons.person_outline),
				selectedIcon: Icon(Icons.person),
				label: 'Perfil',
			),
		];
	}

	@override
	Widget build(BuildContext context) {
		final auth = ref.watch(authControllerProvider);
		final user = auth.session?.usuario;
		final width = MediaQuery.sizeOf(context).width;
		final isMobile = Breakpoints.isMobile(width);
		final canConfig = user?.tieneDerecho('configuracion.usuarios.listar') == true ||
				user?.esAdministrador == true;
		final destinations = _destinations(canConfig);

		if (_selectedIndex >= destinations.length) {
			_selectedIndex = 0;
		}

		final titles = destinations.map((item) => item.label).toList();

		return AdaptiveScaffold(
			title: titles[_selectedIndex],
			selectedIndex: _selectedIndex,
			onDestinationSelected: (index) => setState(() => _selectedIndex = index),
			destinations: destinations,
			body: switch (destinations[_selectedIndex].label) {
				'Config' => _ConfigSection(canConfig: canConfig),
				'Perfil' => _ProfileSection(
						nombreUsuario: user?.nombreUsuario ?? '',
						perfil: user?.perfilNombre,
						sucursal: user?.sucursalNombre,
						esAdmin: user?.esAdministrador ?? false,
						derechosCount: user?.derechos.length ?? 0,
						onLogout: () async {
							await ref.read(authControllerProvider.notifier).logout();
							if (context.mounted) context.go('/login');
						},
					),
				_ => ListView(
						padding: const EdgeInsets.all(16),
						children: [
							_WelcomeCard(
								nombre: user?.nombreUsuario ?? '',
								perfil: user?.perfilNombre,
								sucursal: user?.sucursalNombre,
							),
							const SizedBox(height: 16),
							if (isMobile) const _MobileHomeCards() else const _DesktopDashboard(),
						],
					),
			},
		);
	}
}

class _WelcomeCard extends StatelessWidget {
	const _WelcomeCard({
		required this.nombre,
		required this.perfil,
		required this.sucursal,
	});

	final String nombre;
	final String? perfil;
	final String? sucursal;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: ListTile(
				leading: const CircleAvatar(child: Icon(Icons.person)),
				title: Text('Hola, $nombre'),
				subtitle: Text(
					[
						if (perfil != null) perfil!,
						if (sucursal != null) sucursal! else 'Casa Central',
					].join(' · '),
				),
			),
		);
	}
}

class _ConfigSection extends StatelessWidget {
	const _ConfigSection({required this.canConfig});

	final bool canConfig;

	@override
	Widget build(BuildContext context) {
		if (!canConfig) {
			return const Center(child: Text('Sin permisos de configuración'));
		}

		return ListView(
			padding: const EdgeInsets.all(16),
			children: [
				Card(
					child: ListTile(
						leading: const Icon(Icons.people_outline),
						title: const Text('Usuarios'),
						subtitle: const Text('Alta y gestión de usuarios'),
						trailing: const Icon(Icons.chevron_right),
						onTap: () => context.push('/usuarios'),
					),
				),
				const SizedBox(height: 8),
				Card(
					child: ListTile(
						leading: const Icon(Icons.badge_outlined),
						title: const Text('Perfiles'),
						subtitle: const Text('Perfiles y derechos'),
						trailing: const Icon(Icons.chevron_right),
						onTap: () => context.push('/perfiles'),
					),
				),
				const SizedBox(height: 8),
				Card(
					child: ListTile(
						leading: const Icon(Icons.apartment_outlined),
						title: const Text('Sucursales'),
						subtitle: const Text('Plantas y aislamiento de datos'),
						trailing: const Icon(Icons.chevron_right),
						onTap: () => context.push('/sucursales'),
					),
				),
			],
		);
	}
}

class _ProfileSection extends StatelessWidget {
	const _ProfileSection({
		required this.nombreUsuario,
		required this.perfil,
		required this.sucursal,
		required this.esAdmin,
		required this.derechosCount,
		required this.onLogout,
	});

	final String nombreUsuario;
	final String? perfil;
	final String? sucursal;
	final bool esAdmin;
	final int derechosCount;
	final VoidCallback onLogout;

	@override
	Widget build(BuildContext context) {
		return ListView(
			padding: const EdgeInsets.all(16),
			children: [
				Card(
					child: Padding(
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(nombreUsuario, style: Theme.of(context).textTheme.titleLarge),
								const SizedBox(height: 8),
								Text(perfil ?? (esAdmin ? 'Administrador' : 'Sin perfil')),
								Text(sucursal ?? 'Todas las sucursales'),
								const SizedBox(height: 8),
								Text('$derechosCount derechos efectivos'),
							],
						),
					),
				),
				const SizedBox(height: 16),
				FilledButton.tonalIcon(
					onPressed: onLogout,
					icon: const Icon(Icons.logout),
					label: const Text('Cerrar sesión'),
				),
			],
		);
	}
}

class _MobileHomeCards extends StatelessWidget {
	const _MobileHomeCards();

	@override
	Widget build(BuildContext context) {
		return const Column(
			children: [
				_ActionCard(
					title: 'Mis OT',
					subtitle: 'Próximo módulo: Mantenimiento',
					icon: Icons.assignment,
					color: Colors.blue,
				),
				SizedBox(height: 12),
				_ActionCard(
					title: 'En ejecución',
					subtitle: 'Disponible en Fase 1 OT',
					icon: Icons.play_circle_outline,
					color: Colors.indigo,
				),
				SizedBox(height: 24),
				_OtListTile(
					numero: '#DEMO',
					equipo: 'Silo 103 Arena Fina',
					tipo: 'Preventivo',
					estado: 'pendiente',
				),
			],
		);
	}
}

class _DesktopDashboard extends StatelessWidget {
	const _DesktopDashboard();

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text('Módulo 1 — Seguridad activo', style: Theme.of(context).textTheme.titleLarge),
				const SizedBox(height: 12),
				const Row(
					children: [
						Expanded(child: _StatCard(label: 'Auth', value: 'JWT', color: Colors.blue)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'Permisos', value: 'Árbol', color: Colors.indigo)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'Sucursales', value: '2', color: Colors.green)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'Usuarios demo', value: '5', color: Colors.orange)),
					],
				),
			],
		);
	}
}

class _ActionCard extends StatelessWidget {
	const _ActionCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.color,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: ListTile(
				contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
				leading: CircleAvatar(
					backgroundColor: color.withValues(alpha: 0.12),
					child: Icon(icon, color: color),
				),
				title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
				subtitle: Text(subtitle),
			),
		);
	}
}

class _StatCard extends StatelessWidget {
	const _StatCard({
		required this.label,
		required this.value,
		required this.color,
	});

	final String label;
	final String value;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(label, style: Theme.of(context).textTheme.bodyMedium),
						const SizedBox(height: 8),
						Text(
							value,
							style: Theme.of(context).textTheme.headlineSmall?.copyWith(
										color: color,
										fontWeight: FontWeight.bold,
									),
						),
					],
				),
			),
		);
	}
}

class _OtListTile extends StatelessWidget {
	const _OtListTile({
		required this.numero,
		required this.equipo,
		required this.tipo,
		required this.estado,
	});

	final String numero;
	final String equipo;
	final String tipo;
	final String estado;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: ListTile(
				title: Text('$numero · $equipo'),
				subtitle: Text(tipo),
				trailing: StatusBadge(estado: estado),
			),
		);
	}
}
