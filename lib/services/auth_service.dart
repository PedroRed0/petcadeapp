import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_refs.dart';

/// Login com e-mail/senha e com Google (Firebase Authentication — grátis).
class AuthService {
  FirebaseAuth get _auth => Fb.auth;

  User? get usuarioAtual => _auth.currentUser;
  Stream<User?> get mudancas => _auth.authStateChanges();

  static bool _googleIniciado = false;

  Future<void> entrar(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  /// Entra com a conta Google. Retorna false se a pessoa cancelar.
  Future<bool> entrarComGoogle() async {
    UserCredential cred;
    if (kIsWeb) {
      // No navegador, o próprio Firebase abre a janela do Google.
      cred = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final google = GoogleSignIn.instance;
      if (!_googleIniciado) {
        await google.initialize();
        _googleIniciado = true;
      }
      final GoogleSignInAccount conta;
      try {
        conta = await google.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) return false;
        rethrow;
      }
      final idToken = conta.authentication.idToken;
      cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }
    await _garantirPerfil(cred.user!);
    return true;
  }

  /// Na primeira vez que alguém entra com Google, cria o perfil.
  Future<void> _garantirPerfil(User user) async {
    final doc = Fb.db.collection('usuarios').doc(user.uid);
    final atual = await doc.get();
    if (atual.exists) return;
    await doc.set({
      'nome': user.displayName ?? '',
      'email': user.email ?? '',
      'telefone': user.phoneNumber ?? '',
      'fotoUrl': user.photoURL ?? '',
      'favoritos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> criarConta({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final user = cred.user!;
    await user.updateDisplayName(nome.trim());
    await Fb.db.collection('usuarios').doc(user.uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
      'favoritos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> redefinirSenha(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sair() async {
    if (!kIsWeb && _googleIniciado) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Traduz os erros para mensagens amigáveis.
  static String mensagemErro(Object e) {
    if (e is GoogleSignInException) {
      return 'Não foi possível entrar com o Google (${e.code.name}). '
          'Confira o SHA-1 do app no Firebase.';
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Já existe uma conta com esse e-mail.';
        case 'account-exists-with-different-credential':
          return 'Esse e-mail já tem conta com outro tipo de login.';
        case 'weak-password':
          return 'Senha fraca. Use pelo menos 6 caracteres.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
        case 'network-request-failed':
          return 'Sem conexão com a internet.';
        case 'operation-not-allowed':
          return 'Esse tipo de login não está ativado no Firebase.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Login cancelado.';
      }
      return e.message ?? 'Erro ao autenticar.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
