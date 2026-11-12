import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/tag_service.dart';
import '../services/user_service.dart';

class GatosScreen extends StatefulWidget {
  const GatosScreen({super.key});

  @override
  State<GatosScreen> createState() => GatosScreenState();
}

class GatosScreenState extends State<GatosScreen> {
  static const String _apiUrl = 'https://cataas.com/cat';

  final TextEditingController _wishController = TextEditingController();
  final CatTagService _tagService = CatTagService();

  // ID do gato exibido. A imagem é carregada por /cat/{id}, então o gato da
  // tela é sempre o mesmo que será guardado na biblioteca.
  String? _catId;

  // Tags realmente usadas na busca do gato atual (em inglês).
  List<String> _activeTags = [];

  // Aviso para o usuário (ex.: nenhuma tag encontrada, Gemini indisponível).
  String? _statusMessage;

  // Último pedido interpretado: evita chamar o Gemini de novo (e gastar cota)
  // quando o usuário só quer "outro gato" com o mesmo texto.
  String _interpretedWish = '';
  List<String> _interpretedTags = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  bool _isSaved = false;

  // Identifica a requisição mais recente para descartar respostas atrasadas.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    // Esta tela é recriada toda vez que o usuário volta para ela,
    // então um gato novo é sorteado a cada entrada.
    loadAnotherCat();
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  Future<void> loadAnotherCat() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isSaved = false;
      _catId = null;
      _statusMessage = null;
    });

    try {
      final wish = _wishController.text.trim();
      String? warning;
      var tags = <String>[];

      // 1) Interpretar o pedido com o Gemini (se houver texto).
      if (wish.isNotEmpty) {
        if (wish == _interpretedWish) {
          tags = _interpretedTags;
        } else {
          try {
            tags = await _tagService.extractTags(wish);
            if (!mounted || requestId != _requestId) return;
            _interpretedWish = wish;
            _interpretedTags = tags;
          } catch (e) {
            if (!mounted || requestId != _requestId) return;
            debugPrint('Erro ao interpretar o pedido: $e');
            warning = 'Não foi possível interpretar o pedido ($e). '
                'Mostrando um gato aleatório.';
          }
        }
        if (tags.isEmpty && warning == null) {
          warning = 'Não encontrei uma tag que combine com esse pedido. '
              'Mostrando um gato aleatório.';
        }
      }

      // 2) Buscar o gato na Cataas, com fallback progressivo.
      final result = await _fetchCat(tags);
      if (!mounted || requestId != _requestId) return;
      if (result == null) {
        throw StateError('Não foi possível obter um gato da API.');
      }

      if (tags.isNotEmpty && result.tags.length < tags.length) {
        final used = result.tags.isEmpty
            ? 'um gato aleatório'
            : 'gatos com "${result.tags.join(', ')}"';
        warning = 'Não há gatos com todas as tags "${tags.join(', ')}". '
            'Mostrando $used.';
      }

      setState(() {
        _catId = result.id;
        _activeTags = result.tags;
        _statusMessage = warning;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar gato: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Tenta todas as tags; se não houver gato, só a primeira; se ainda assim
  /// não houver, um gato aleatório. Devolve o id e as tags que funcionaram.
  Future<({String id, List<String> tags})?> _fetchCat(List<String> tags) async {
    final attempts = <List<String>>[
      if (tags.isNotEmpty) tags,
      if (tags.length > 1) [tags.first],
      <String>[],
    ];

    for (final attempt in attempts) {
      final id = await _requestCatId(attempt);
      if (id != null) return (id: id, tags: attempt);
    }
    return null;
  }

  Future<String?> _requestCatId(List<String> tags) async {
    try {
      // Tags com espaço viram %20 (ex.: "big eyes" -> big%20eyes).
      final path = tags.isEmpty
          ? _apiUrl
          : '$_apiUrl/${tags.map(Uri.encodeComponent).join(',')}';
      // json=true devolve os metadados (incluindo o id) em vez da imagem;
      // "t" evita cache devolvendo sempre o mesmo gato.
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final response = await http
          .get(Uri.parse('$path?json=true&t=$stamp'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final id = data is Map ? (data['id'] ?? data['_id']) : null;
      return id is String && id.isNotEmpty ? id : null;
    } catch (e) {
      debugPrint('Falha ao buscar gato (tags: $tags): $e');
      return null;
    }
  }

  String _describeError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'sem permissão no Firestore (verifique as regras de segurança)';
        case 'unauthenticated':
          return 'usuário não autenticado';
        case 'unavailable':
          return 'sem conexão com o Firestore';
        default:
          return '${e.code}: ${e.message ?? ''}';
      }
    }
    return '$e';
  }

  Future<void> _saveCat() async {
    final catId = _catId;
    if (catId == null || _isSaving || _isSaved) return;

    final requestId = _requestId;
    setState(() => _isSaving = true);
    try {
      await UserService().saveCat(catId);
      if (!mounted) return;
      // Só marca como salvo se o usuário ainda estiver olhando para o mesmo gato.
      if (requestId == _requestId) setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gato guardado na biblioteca!')),
      );
    } catch (e) {
      debugPrint('Erro ao guardar o gato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível guardar o gato: ${_describeError(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildWishField() {
    return TextField(
      controller: _wishController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => loadAnotherCat(),
      decoration: InputDecoration(
        hintText: 'Ex.: quero gatos brancos e fofinhos',
        helperText: CatTagService.isConfigured
            ? null
            : 'Gemini não configurado: o texto será ignorado.',
        prefixIcon: const Icon(Icons.auto_awesome_outlined),
        suffixIcon: IconButton(
          tooltip: 'Limpar',
          icon: const Icon(Icons.close),
          onPressed: () => _wishController.clear(),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final message = _statusMessage;
    if (_activeTags.isEmpty && message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeTags.isNotEmpty)
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Tags:', style: TextStyle(fontSize: 13)),
                for (final tag in _activeTags)
                  Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          if (message != null)
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
        ],
      ),
    );
  }

  Widget _buildRetry() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar o gato.'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: loadAnotherCat,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final catId = _catId;
    if (_hasError || catId == null) {
      return _buildRetry();
    }
    // contain: o gato inteiro sempre aparece dentro da moldura, sem cortes.
    return Image.network(
      UserService.catImageUrl(catId),
      key: ValueKey(catId),
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => _buildRetry(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _catId != null && !_isSaving && !_isSaved;
    final saveLabel = _isSaving
        ? 'Guardando...'
        : _isSaved
            ? 'Gato guardado'
            : 'Guardar gato';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gatos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Diga que tipo de gato você quer e toque em "Outro gato".'),
          const SizedBox(height: 16),
          _buildWishField(),
          _buildStatus(),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: _buildImage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: canSave ? _saveCat : null,
            icon: Icon(
              _isSaved ? Icons.bookmark_added_outlined : Icons.bookmark_add_outlined,
            ),
            label: Text(saveLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : loadAnotherCat,
            icon: const Icon(Icons.refresh),
            label: const Text('Outro gato'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
