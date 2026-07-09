import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/sika_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class DerechoNode {
	DerechoNode({
		required this.id,
		required this.codigo,
		required this.nombre,
		required this.habilitado,
		required this.modoTotal,
		this.children = const [],
		this.expanded = true,
	});

	final String id;
	final String codigo;
	final String nombre;
	bool habilitado;
	bool modoTotal;
	List<DerechoNode> children;
	bool expanded;

	factory DerechoNode.fromJson(Map<String, dynamic> json) {
		final childrenRaw = json['children'] as List<dynamic>? ?? [];
		return DerechoNode(
			id: json['id'] as String,
			codigo: json['codigo'] as String,
			nombre: json['nombre'] as String,
			habilitado: json['habilitado'] as bool? ?? false,
			modoTotal: json['modoTotal'] as bool? ?? false,
			children: childrenRaw
					.map((c) => DerechoNode.fromJson(c as Map<String, dynamic>))
					.toList(),
		);
	}

	bool get hasChildren => children.isNotEmpty;
}

class PerfilDerechosPage extends ConsumerStatefulWidget {
	const PerfilDerechosPage({
		super.key,
		required this.perfilId,
		this.perfilNombre,
	});

	final String perfilId;
	final String? perfilNombre;

	@override
	ConsumerState<PerfilDerechosPage> createState() => _PerfilDerechosPageState();
}

class _PerfilDerechosPageState extends ConsumerState<PerfilDerechosPage> {
	bool _loading = true;
	bool _saving = false;
	String? _error;
	String _titulo = 'Derechos del perfil';
	List<DerechoNode> _roots = [];

	@override
	void initState() {
		super.initState();
		_titulo = widget.perfilNombre ?? _titulo;
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});

		try {
			final api = ref.read(apiClientProvider);
			final perfil = await api.getJson('perfiles/${widget.perfilId}');
			final tree = await api.getList('perfiles/${widget.perfilId}/derechos');

			if (!mounted) return;
			setState(() {
				_titulo = 'Derechos — ${perfil['nombre'] ?? widget.perfilNombre ?? ''}';
				_roots = tree
						.map((n) => DerechoNode.fromJson(n as Map<String, dynamic>))
						.toList();
				_loading = false;
			});
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_error = error.toString();
				_loading = false;
			});
		}
	}

	bool _heredado(DerechoNode node, List<DerechoNode> ancestors) {
		for (final a in ancestors.reversed) {
			if (a.habilitado && a.modoTotal) return true;
		}
		return false;
	}

	void _setHabilitado(DerechoNode node, bool value) {
		node.habilitado = value;
		if (!value) {
			node.modoTotal = false;
			_clearDescendants(node);
		} else if (node.hasChildren) {
			node.modoTotal = true;
			_clearDescendants(node);
		}
	}

	void _clearDescendants(DerechoNode node) {
		for (final child in node.children) {
			child.habilitado = false;
			child.modoTotal = false;
			_clearDescendants(child);
		}
	}

	void _setModoTotal(DerechoNode node, bool total) {
		node.modoTotal = total;
		if (total) {
			_clearDescendants(node);
		}
	}

	List<Map<String, dynamic>> _collectPayload(
		List<DerechoNode> nodes, {
		bool underTotalParent = false,
	}) {
		final out = <Map<String, dynamic>>[];
		for (final node in nodes) {
			if (node.habilitado && !underTotalParent) {
				out.add({
					'derechoId': node.id,
					'habilitado': true,
					'modoTotal': node.modoTotal,
				});
			}
			final skipChildren =
					node.habilitado && node.modoTotal && node.hasChildren;
			if (!skipChildren) {
				out.addAll(_collectPayload(node.children, underTotalParent: underTotalParent));
			}
		}
		return out;
	}

	Future<void> _guardar() async {
		setState(() {
			_saving = true;
			_error = null;
		});

		try {
			await ref.read(apiClientProvider).putJson(
				'perfiles/${widget.perfilId}/derechos',
				{'derechos': _collectPayload(_roots)},
			);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Derechos guardados')),
			);
			context.pop(true);
		} catch (error) {
			if (!mounted) return;
			setState(() {
				_error = error.toString();
				_saving = false;
			});
		}
	}

	Widget _buildNode(DerechoNode node, int depth, List<DerechoNode> ancestors) {
		final heredado = _heredado(node, ancestors);
		final marcado = node.habilitado || heredado;
		final scheme = Theme.of(context).colorScheme;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Material(
					color: scheme.surfaceContainerLowest,
					borderRadius: BorderRadius.circular(12),
					child: Padding(
						padding: EdgeInsets.fromLTRB(12 + depth * 16.0, 8, 12, 8),
						child: Row(
							children: [
								if (node.hasChildren)
									IconButton(
										visualDensity: VisualDensity.compact,
										onPressed: () => setState(() => node.expanded = !node.expanded),
										icon: Icon(
											node.expanded
													? Icons.expand_more_rounded
													: Icons.chevron_right_rounded,
											size: 20,
										),
									)
								else
									const SizedBox(width: 40),
								Checkbox(
									value: marcado,
									onChanged: heredado
											? null
											: (v) => setState(() => _setHabilitado(node, v ?? false)),
								),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												node.nombre,
												style: const TextStyle(fontWeight: FontWeight.w600),
											),
											Text(
												node.codigo,
												style: TextStyle(
													fontSize: 12,
													color: scheme.onSurfaceVariant,
												),
											),
										],
									),
								),
								if (node.hasChildren && node.habilitado && !heredado)
									SegmentedButton<bool>(
										segments: const [
											ButtonSegment(value: true, label: Text('Total')),
											ButtonSegment(value: false, label: Text('Parcial')),
										],
										selected: {node.modoTotal},
										onSelectionChanged: (s) =>
												setState(() => _setModoTotal(node, s.first)),
										style: const ButtonStyle(
											visualDensity: VisualDensity.compact,
										),
									),
								if (heredado)
									Padding(
										padding: const EdgeInsets.only(left: 8),
										child: Text(
											'Heredado',
											style: TextStyle(
												fontSize: 11,
												color: AppColors.accent.withValues(alpha: 0.9),
											),
										),
									),
							],
						),
					),
				),
				if (node.expanded && node.hasChildren) ...[
					const SizedBox(height: 6),
					...node.children.map(
						(c) => Padding(
							padding: const EdgeInsets.only(bottom: 6),
							child: _buildNode(c, depth + 1, [...ancestors, node]),
						),
					),
				],
			],
		);
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				SikaPageHeader(
					title: _titulo,
					subtitle: 'Total habilita todos los hijos · Parcial permite elegir por nodo',
					icon: Icons.account_tree_outlined,
					trailing: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							TextButton(
								onPressed: _saving ? null : () => context.pop(),
								child: const Text('Cancelar'),
							),
							const SizedBox(width: 8),
							FilledButton(
								onPressed: _saving || _loading ? null : _guardar,
								child: _saving
										? const SizedBox(
												width: 18,
												height: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Text('Guardar'),
							),
						],
					),
				),
				if (_error != null)
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
						child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
					),
				Expanded(
					child: _loading
							? const Center(child: CircularProgressIndicator())
							: ListView(
									padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
									children: _roots
											.map(
												(n) => Padding(
													padding: const EdgeInsets.only(bottom: 8),
													child: _buildNode(n, 0, const []),
												),
											)
											.toList(),
								),
				),
			],
		);
	}
}
