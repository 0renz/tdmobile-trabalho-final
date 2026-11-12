import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';

class GatosScreen extends StatefulWidget {
  const GatosScreen({super.key});

  @override
  State<GatosScreen> createState() => GatosScreenState();
}

class GatosScreenState extends State<GatosScreen> {
  static const String _apiUrl = 'https://cataas.com/cat';

  // ID do gato exibido. A imagem é carregada por /cat/{id}, então o gato da
  // tela é sempre o mesmo que será guardado na biblioteca.
  String? _catId;

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

  Future<void> loadAnotherCat() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isSaved = false;
      _catId = null;
    });

    try {
      // json=true devolve os metadados do gato sorteado (incluindo o id)
      // em vez da imagem. "t" evita cache devolvendo sempre o mesmo gato.
      final uri = Uri.parse(_apiUrl).replace(
        queryParameters: {
          'json': 'true',
          't': DateTime.now().microsecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (!mounted || requestId != _requestId) return;

      if (response.statusCode != 200) {
        throw StateError('Resposta inválida da API (HTTP ${response.statusCode}).');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final id = data is Map ? (data['id'] ?? data['_id']) : null;
      if (id is! String || id.isEmpty) {
        throw StateError('A API não devolveu o id do gato.');
      }

      setState(() {
        _catId = id;
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
          const Text('Veja um gato e atualize para encontrar outro.'),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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
