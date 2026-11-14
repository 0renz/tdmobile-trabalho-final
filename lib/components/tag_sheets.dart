import 'package:flutter/material.dart';
import '../components/confirm_dialog.dart';
import '../models/saved_cat.dart';
import '../services/tag_service.dart';
import '../services/user_service.dart';

/// Moldura comum das janelas inferiores: acompanha o teclado e limita a
/// altura para que a lista interna role sem estourar a tela.
class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SheetFrame({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 16;
    final height = available < media.size.height * 0.8
        ? available
        : media.size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _searchDecoration(String label) {
  return InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.search),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

/// Janela do filtro: lista (com busca) só as tags que existem na biblioteca,
/// com a quantidade de gatos de cada uma. Cada toque já atualiza o filtro.
class TagFilterSheet extends StatefulWidget {
  final Map<String, int> counts;
  final Set<String> initialSelected;
  final ValueChanged<Set<String>> onChanged;

  const TagFilterSheet({
    super.key,
    required this.counts,
    required this.initialSelected,
    required this.onChanged,
  });

  @override
  State<TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<TagFilterSheet> {
  late final Set<String> _selected = {...widget.initialSelected};
  String _query = '';

  void _toggle(String tag, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(tag);
      } else {
        _selected.remove(tag);
      }
    });
    widget.onChanged({..._selected});
  }

  void _clear() {
    setState(_selected.clear);
    widget.onChanged({});
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.counts.keys
        .where((t) => t.contains(_query.trim().toLowerCase()))
        .toList()
      ..sort();

    return _SheetFrame(
      title: 'Filtrar por tags',
      trailing: TextButton(
        onPressed: _selected.isEmpty ? null : _clear,
        child: const Text('Limpar'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextField(
            decoration: _searchDecoration('Buscar tag'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tags.isEmpty
                ? const Center(child: Text('Nenhuma tag encontrada.'))
                : ListView.builder(
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(tag),
                        secondary: Text('${widget.counts[tag]}'),
                        value: _selected.contains(tag),
                        onChanged: (value) => _toggle(tag, value ?? false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Janela de edição das tags de um gato. Cada alteração é gravada no
/// Firestore na hora; a biblioteca e o filtro se atualizam sozinhos porque
/// escutam o mesmo stream.
class EditTagsSheet extends StatefulWidget {
  final SavedCat cat;
  final UserService userService;

  const EditTagsSheet({
    super.key,
    required this.cat,
    required this.userService,
  });

  @override
  State<EditTagsSheet> createState() => _EditTagsSheetState();
}

class _EditTagsSheetState extends State<EditTagsSheet> {
  late final List<String> _tags = [...widget.cat.tags];
  late Future<List<String>> _availableFuture =
      CatTagService().fetchAvailableTags();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addTag(String tag) async {
    if (_busy || _tags.contains(tag)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.userService.addTag(widget.cat.id, tag);
      if (!mounted) return;
      setState(() {
        _tags.add(tag);
        _tags.sort();
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Não foi possível adicionar a tag: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeTag(String tag) async {
    if (_busy) return;
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Remover tag',
      mensagem: 'Remover a tag "$tag" deste gato?',
      confirmarTexto: 'Remover',
    );
    if (!confirmado || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.userService.removeTag(widget.cat.id, tag);
      if (!mounted) return;
      setState(() {
        _tags.remove(tag);
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Não foi possível remover a tag: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildCurrentTags() {
    if (_tags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Este gato ainda não tem tags.'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 96),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tag in _tags)
              InputChip(
                label: Text(tag),
                onDeleted: _busy ? null : () => _removeTag(tag),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTags() {
    return FutureBuilder<List<String>>(
      future: _availableFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data ?? const <String>[];
        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar as tags do Cataas.'),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _availableFuture = CatTagService().fetchAvailableTags();
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final query = _query.trim().toLowerCase();
        final options = all
            .where((t) => !_tags.contains(t) && t.contains(query))
            .toList();

        if (options.isEmpty) {
          return Center(
            child: Text(
              query.isEmpty
                  ? 'Este gato já tem todas as tags disponíveis.'
                  : 'Nenhuma tag encontrada para "$query".',
            ),
          );
        }

        return ListView.builder(
          itemCount: options.length,
          itemBuilder: (context, index) {
            final tag = options[index];
            return ListTile(
              dense: true,
              title: Text(tag),
              trailing: const Icon(Icons.add_circle_outline),
              enabled: !_busy,
              onTap: () => _addTag(tag),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Editar tags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildCurrentTags(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          const Divider(height: 24),
          TextField(
            controller: _searchController,
            decoration: _searchDecoration('Adicionar tag (digite para buscar)'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildAvailableTags()),
        ],
      ),
    );
  }
}
