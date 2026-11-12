import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore
      .instance
      .collection('users');

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    try {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'displayName': name.trim(),
        'email': email.trim(),
        'photoURL': '',
      });
    } catch (_) {
      // Do not leave an authenticated account without its application profile.
      await user.delete();
      rethrow;
    }

    return credential;
  }

  Future<UserModel?> getUser() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    try {
      final doc = await _users.doc(user.uid).get();

      if (!doc.exists) {
        debugPrint('Documento do usuário não encontrado: ${user.uid}');
        return null;
      }

      return UserModel.fromSnap(doc);
    } on FirebaseException catch (e) {
      debugPrint('Erro Firestore: ${e.code}');
      debugPrint('Mensagem: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGitHub() async {
    final githubProvider = GithubAuthProvider();
    githubProvider.addScope('user:email');

    final UserCredential userCredential;

    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(githubProvider);
    } else {
      userCredential = await _auth.signInWithProvider(githubProvider);
    }

    final user = userCredential.user;

    if (user != null) {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  CollectionReference<Map<String, dynamic>> _savedCats(String uid) {
    return _users.doc(uid).collection('savedCats');
  }

  /// URL fixa de um gato específico da Cataas (ao contrário de /cat, que
  /// sorteia um gato diferente a cada requisição).
  static String catImageUrl(String catId) => 'https://cataas.com/cat/$catId';

  /// Guarda apenas o ID do gato no Firestore; a imagem continua hospedada na
  /// Cataas. O ID é usado como id do documento, então guardar o mesmo gato
  /// duas vezes não cria duplicatas.
  Future<void> saveCat(String catId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para guardar um gato.');
    }

    await _savedCats(user.uid).doc(catId).set({
      'catId': catId,
      'imageUrl': catImageUrl(catId),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> savedCatsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para acessar a biblioteca.');
    }

    return _savedCats(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteCat(String catId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para excluir um gato.');
    }

    await _savedCats(user.uid).doc(catId).delete();
  }
}
