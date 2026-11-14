import 'package:cloud_firestore/cloud_firestore.dart';

/// Gato guardado na biblioteca (documento em users/{uid}/savedCats/{catId}).
class SavedCat {
  final String id;
  final String imageUrl;
  final List<String> tags;

  const SavedCat({
    required this.id,
    required this.imageUrl,
    required this.tags,
  });

  /// Devolve null para documentos sem imagem. Documentos antigos, criados
  /// antes das tags existirem, simplesmente não têm o campo "tags".
  static SavedCat? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final imageUrl = data['imageUrl'];
    if (imageUrl is! String || imageUrl.isEmpty) return null;

    final rawTags = data['tags'];
    final tags = rawTags is List
        ? (rawTags.whereType<String>().toList()..sort())
        : <String>[];

    return SavedCat(id: doc.id, imageUrl: imageUrl, tags: tags);
  }
}
