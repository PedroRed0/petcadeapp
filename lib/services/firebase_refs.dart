import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ponto único de acesso ao Firebase.
/// Nos testes, trocamos por versões simuladas com [Fb.usar].
class Fb {
  Fb._();

  static FirebaseFirestore? _db;
  static FirebaseAuth? _auth;

  static FirebaseFirestore get db => _db ?? FirebaseFirestore.instance;
  static FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  @visibleForTesting
  static void usar({FirebaseFirestore? db, FirebaseAuth? auth}) {
    _db = db;
    _auth = auth;
  }
}
