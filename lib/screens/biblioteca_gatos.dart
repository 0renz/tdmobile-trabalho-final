import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';

class BibliotecaGatosScreen extends StatelessWidget {
  const BibliotecaGatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userService.savedCatsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Não foi possível carregar a biblioteca: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cats = snapshot.data?.docs ?? [];
        if (cats.isEmpty) {
          return const Center(
            child: Text('Sua biblioteca ainda está vazia.'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final cat = cats[index];
            final imageUrl = cat.data()['imageUrl'] as String?;
            if (imageUrl == null || imageUrl.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Imagem indisponível'),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir gato',
                    onPressed: () => _deleteCat(context, userService, cat.id),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCat(
    BuildContext context,
    UserService userService,
    String catId,
  ) async {
    try {
      await userService.deleteCat(catId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gato excluído da biblioteca.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir o gato: $e')),
        );
      }
    }
  }
}
