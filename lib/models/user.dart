import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String displayName;
  String email;
  String photoURL;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoURL': photoURL,
  };

  static UserModel? fromSnap(DocumentSnapshot snap) {
    return UserModel(
      uid: snap['uid'],
      displayName: snap['displayName'],
      email: snap['email'],
      photoURL: snap['photoURL'],
    );
  }
}
