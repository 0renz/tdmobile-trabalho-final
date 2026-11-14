import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/confirm_dialog.dart';
import '../components/tag_sheets.dart';
import '../models/saved_cat.dart';
import '../services/user_service.dart';

class BibliotecaGatosScreen extends StatefulWidget {
  const BibliotecaGatosScreen({super.key});

  @override
  State<BibliotecaGatosScreen> createState() => _BibliotecaGatosScreenState();
}

class _BibliotecaGatosScreenState extends State<BibliotecaGatosScreen> {
  final UserService _userService = UserService();

  // O stream é criado uma vez só (antes era recriado a cada rebuild).
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _userService.savedCatsStream();

  // Tags escolhidas no filtro. Vazio = todos os gatos aparecem.
  final Set<String> _selectedTags = {};

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFilter(Map<String, int> counts) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TagFilterSheet(
        counts: counts,
        initialSelected: {..._selectedTags},
        onChanged: (tags) => setState(() {
          _selectedTags
            ..clear()
            ..addAll(tags);
        }),
      ),
    );
  }

  Future<void> _editTags(SavedCat cat) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditTagsSheet(cat: cat, userService: _userService),
    );
  }

  Future<void> _deleteCat(SavedCat cat) async {
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Excluir gato',
      mensagem: 'Tem certeza de que deseja excluir este gato da biblioteca?',
    );
    if (!confirmado) return;

    try {
      await _userService.deleteCat(cat.id);
      _showMessage('Gato excluído da biblioteca.');
    } catch (e) {
      _showMessage('Não foi possível excluir o gato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Não foi possível carregar a biblioteca: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cats = (snapshot.data?.docs ?? [])
            .map(SavedCat.fromDoc)
            .whereType<SavedCat>()
            .toList();
        if (cats.isEmpty) {
          return const Center(
            child: Text('Sua biblioteca ainda está vazia.'),
          );
        }

        // Tags presentes no banco agora, com a quantidade de gatos de cada.
        // Recalculado a cada atualização do stream, então editar ou excluir
        // gatos atualiza o filtro automaticamente.
        final counts = <String, int>{};
        for (final cat in cats) {
          for (final tag in cat.tags) {
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }

        // Tags selecionadas que já não existem em nenhum gato saem do filtro.
        final selected = _selectedTags.where(counts.containsKey).toSet();
        if (selected.length != _selectedTags.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedTags.retainAll(counts.keys.toSet()));
            }
          });
        }

        // Só aparecem gatos que têm todas as tags selecionadas.
        final visible = selected.isEmpty
            ? cats
            : cats.where((c) => selected.every(c.tags.contains)).toList();

        return Column(
          children: [
            if (counts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TagFilterField(
                  selected: selected,
                  onTap: () => _openFilter(counts),
                  onRemove: (tag) => setState(() => _selectedTags.remove(tag)),
                  onClear: () => setState(_selectedTags.clear),
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Nenhum gato com todas essas tags.'),
                          TextButton(
                            onPressed: () => setState(_selectedTags.clear),
                            child: const Text('Limpar filtro'),
                          ),
                        ],
                      ),
                    )
                  : _buildGrid(visible),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(List<SavedCat> cats) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  // contain: mostra o gato inteiro, sem cortar as bordas.
                  child: Image.network(
                    cat.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Imagem indisponível'));
                    },
                  ),
                ),
              ),
              _CatTagsRow(tags: cat.tags),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Editar tags',
                    onPressed: () => _editTags(cat),
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.deepPurple,
                  ),
                  IconButton(
                    tooltip: 'Excluir gato',
                    onPressed: () => _deleteCat(cat),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Faixa de tags de um gato, com rolagem horizontal quando não cabem todas.
class _CatTagsRow extends StatelessWidget {
  final List<String> tags;

  const _CatTagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: tags.isEmpty
          ? Center(
              child: Text(
                'Sem tags',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                return Center(
                  child: Chip(
                    label: Text(tags[index], style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
    );
  }
}

/// Campo do filtro: mostra as tags escolhidas (ou "Todas as tags") e abre a
/// janela de seleção ao ser tocado.
class _TagFilterField extends StatelessWidget {
  final Set<String> selected;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _TagFilterField({
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = selected.toList()..sort();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: 'Filtrar por tags',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.filter_list),
          suffixIcon: selected.isEmpty
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  tooltip: 'Limpar filtro',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        child: selected.isEmpty
            ? Text(
                'Todas as tags',
                style: TextStyle(color: Colors.grey.shade600),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in sorted)
                    InputChip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      onPressed: onTap,
                      onDeleted: () => onRemove(tag),
                    ),
                ],
              ),
      ),
    );
  }
}
