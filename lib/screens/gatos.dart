import 'package:flutter/material.dart';
import '../services/user_service.dart';

class GatosScreen extends StatefulWidget {
  const GatosScreen({super.key});

  @override
  State<GatosScreen> createState() => GatosScreenState();
}

class GatosScreenState extends State<GatosScreen> {
  static const String _apiUrl = 'https://cataas.com/cat';
  late String _imageUrl;
  int _requestId = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    loadAnotherCat();
  }

  void loadAnotherCat() {
    setState(() {
      _requestId++;
      _imageUrl = '$_apiUrl?request=$_requestId';
    });
  }

  Future<void> _saveCat() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await UserService().saveCat(_imageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gato guardado na biblioteca!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível guardar o gato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Não foi possível carregar o gato.'),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCat,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar gato'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: loadAnotherCat,
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
