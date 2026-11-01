import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login e cadastro com e-mail e senha (Firebase Authentication — grátis).
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get usuarioAtual => _auth.currentUser;
  Stream<User?> get mudancas => _auth.authStateChanges();

  Future<void> entrar(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
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
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
      'favoritos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> redefinirSenha(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sair() => _auth.signOut();

  /// Traduz os erros do Firebase para mensagens amigáveis.
  static String mensagemErro(Object e) {
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
        case 'weak-password':
          return 'Senha fraca. Use pelo menos 6 caracteres.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
        case 'network-request-failed':
          return 'Sem conexão com a internet.';
        case 'operation-not-allowed':
          return 'Login por e-mail não está ativado no Firebase.';
      }
      return e.message ?? 'Erro ao autenticar.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
