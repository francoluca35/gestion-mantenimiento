import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_scaffold.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/status_badge.dart';

class HomePage extends StatefulWidget {
	const HomePage({super.key});

	@override
	State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
	int _selectedIndex = 0;
	String _apiStatus = 'Verificando API...';
	bool _apiOk = false;

	static const _destinations = [
		NavigationDestination(
			icon: Icon(Icons.home_outlined),
			selectedIcon: Icon(Icons.home),
			label: 'Inicio',
		),
		NavigationDestination(
			icon: Icon(Icons.assignment_outlined),
			selectedIcon: Icon(Icons.assignment),
			label: 'Mis OT',
		),
		NavigationDestination(
			icon: Icon(Icons.notifications_outlined),
			selectedIcon: Icon(Icons.notifications),
			label: 'Avisos',
		),
		NavigationDestination(
			icon: Icon(Icons.person_outline),
			selectedIcon: Icon(Icons.person),
			label: 'Perfil',
		),
	];

	@override
	void initState() {
		super.initState();
		_checkApi();
	}

	Future<void> _checkApi() async {
		try {
			final client = ApiClient();
			final health = await client.getJson('health');
			if (!mounted) return;
			setState(() {
				_apiOk = health['status'] == 'ok';
				_apiStatus = _apiOk
						? 'API conectada · storage: ${health['storageProvider']}'
						: 'API respondió con error';
			});
		} catch (_) {
			if (!mounted) return;
			setState(() {
				_apiOk = false;
				_apiStatus = 'API no disponible (¿está corriendo NestJS?)';
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		final width = MediaQuery.sizeOf(context).width;
		final isMobile = Breakpoints.isMobile(width);

		return AdaptiveScaffold(
			title: isMobile ? 'Mis OT' : 'Dashboard',
			selectedIndex: _selectedIndex,
			onDestinationSelected: (index) => setState(() => _selectedIndex = index),
			destinations: _destinations,
			body: ListView(
				padding: const EdgeInsets.all(16),
				children: [
					_ApiStatusCard(ok: _apiOk, message: _apiStatus, onRetry: _checkApi),
					const SizedBox(height: 16),
					if (isMobile) ...[
						_MobileHomeCards(),
					] else ...[
						_DesktopDashboard(),
					],
				],
			),
		);
	}
}

class _ApiStatusCard extends StatelessWidget {
	const _ApiStatusCard({
		required this.ok,
		required this.message,
		required this.onRetry,
	});

	final bool ok;
	final String message;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: ListTile(
				leading: Icon(
					ok ? Icons.cloud_done : Icons.cloud_off,
					color: ok ? Colors.green : Colors.orange,
				),
				title: Text(message),
				trailing: IconButton(
					onPressed: onRetry,
					icon: const Icon(Icons.refresh),
				),
			),
		);
	}
}

class _MobileHomeCards extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				_ActionCard(
					title: 'Mis OT',
					subtitle: '3 pendientes',
					icon: Icons.assignment,
					color: Colors.blue,
				),
				const SizedBox(height: 12),
				_ActionCard(
					title: 'En ejecución',
					subtitle: '1 activa',
					icon: Icons.play_circle_outline,
					color: Colors.indigo,
				),
				const SizedBox(height: 12),
				_ActionCard(
					title: 'Realizadas',
					subtitle: '12 este mes',
					icon: Icons.check_circle_outline,
					color: Colors.green,
				),
				const SizedBox(height: 24),
				Text(
					'Órdenes recientes',
					style: Theme.of(context).textTheme.titleMedium,
				),
				const SizedBox(height: 8),
				const _OtListTile(
					numero: '#1234',
					equipo: 'Silo 103 Arena Fina',
					tipo: 'Preventivo',
					estado: 'pendiente',
				),
				const _OtListTile(
					numero: '#1235',
					equipo: 'Bomba B2',
					tipo: 'Correctivo',
					estado: 'en_ejecucion',
				),
			],
		);
	}
}

class _DesktopDashboard extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					'Resumen operativo',
					style: Theme.of(context).textTheme.titleLarge,
				),
				const SizedBox(height: 12),
				Row(
					children: const [
						Expanded(child: _StatCard(label: 'Pendientes', value: '12', color: Colors.orange)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'En ejecución', value: '8', color: Colors.blue)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'Realizadas', value: '45', color: Colors.green)),
						SizedBox(width: 12),
						Expanded(child: _StatCard(label: 'Vencidas', value: '3', color: Colors.red)),
					],
				),
				const SizedBox(height: 24),
				Text(
					'OT recientes',
					style: Theme.of(context).textTheme.titleMedium,
				),
				const SizedBox(height: 8),
				Card(
					child: Column(
						children: const [
							_OtListTile(
								numero: '#1234',
								equipo: 'Silo 103 Arena Fina',
								tipo: 'Preventivo',
								estado: 'pendiente',
							),
							Divider(height: 1),
							_OtListTile(
								numero: '#1235',
								equipo: 'Bomba B2',
								tipo: 'Correctivo',
								estado: 'en_ejecucion',
							),
							Divider(height: 1),
							_OtListTile(
								numero: '#1236',
								equipo: 'Filtro A1',
								tipo: 'Preventivo',
								estado: 'realizada',
							),
						],
					),
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
				trailing: const Icon(Icons.chevron_right),
				onTap: () {},
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
							style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
		return ListTile(
			title: Text('$numero · $equipo'),
			subtitle: Text(tipo),
			trailing: StatusBadge(estado: estado),
			onTap: () {},
		);
	}
}
