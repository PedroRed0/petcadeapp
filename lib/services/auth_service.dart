import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';
import 'firebase_refs.dart';
import 'perfil_service.dart';

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
    if (kIsWeb) {
      // No navegador, o próprio Firebase abre a janela do Google.
      try {
        await _auth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          return false;
        }
        if (e.code == 'popup-blocked' ||
            e.code == 'operation-not-supported-in-this-environment') {
          // iPhone (app na tela inicial) costuma bloquear popups:
          // abre o Google na mesma janela e volta logado.
          await _auth.signInWithRedirect(GoogleAuthProvider());
          return false;
        }
        rethrow;
      }
    } else {
      try {
        final c = await _entrarComGoogleNativo();
        if (c == null) return false; // cancelou
      } on GoogleSignInException catch (e) {
        // Falta configuração (ex.: "ID do cliente da Web"): tenta pelo
        // fluxo do próprio Firebase, que abre o Google no navegador.
        if (e.code != GoogleSignInExceptionCode.clientConfigurationError &&
            e.code != GoogleSignInExceptionCode.providerConfigurationError) {
          rethrow;
        }
        try {
          await _auth.signInWithProvider(GoogleAuthProvider());
        } on FirebaseAuthException catch (e2) {
          if (e2.code == 'web-context-canceled' ||
              e2.code == 'canceled' ||
              e2.code == 'popup-closed-by-user') {
            return false;
          }
          throw GoogleConfigException(e.code.name, e2.code);
        }
      }
    }
    await garantirPerfil();
    return true;
  }

  /// Login pela tela nativa do Android/iOS (Credential Manager).
  Future<UserCredential?> _entrarComGoogleNativo() async {
    final google = GoogleSignIn.instance;
    if (!_googleIniciado) {
      await google.initialize(
        serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
      );
      _googleIniciado = true;
    }
    final GoogleSignInAccount conta;
    try {
      conta = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: conta.authentication.idToken),
    );
  }

  /// Na primeira vez que alguém entra com Google, cria o perfil.
  /// (Chamado também ao abrir o app, para o login por redirecionamento.)
  Future<void> garantirPerfil() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = Fb.db.collection('usuarios').doc(user.uid);
    final atual = await doc.get();
    if (atual.exists) {
      await PerfilService().sincronizar();
      return;
    }
    await doc.set({
      'nome': user.displayName ?? '',
      'email': user.email ?? '',
      'telefone': user.phoneNumber ?? '',
      'fotoUrl': user.photoURL ?? '',
      'favoritos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
    await PerfilService().sincronizar();
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
    // Envia o link de confirmação para o e-mail.
    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Sem problema: dá para reenviar depois pelo app.
    }
    await Fb.db.collection('usuarios').doc(user.uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
      'favoritos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Confirmação de e-mail ----------

  /// E-mail confirmado? (Contas Google já vêm confirmadas.)
  bool get emailConfirmado => _auth.currentUser?.emailVerified ?? false;

  Future<void> reenviarConfirmacao() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Busca no Firebase se a pessoa já clicou no link de confirmação.
  /// Também renova a "credencial" para as regras do banco enxergarem.
  Future<bool> atualizarConfirmacao() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final atualizado = _auth.currentUser;
    if (atualizado?.emailVerified ?? false) {
      await atualizado!.getIdToken(true);
      return true;
    }
    return false;
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
    if (e is GoogleConfigException) {
      return 'O login com Google ainda não está configurado neste app '
          '(${e.codigoNativo} / ${e.codigoFirebase}). Veja o passo a passo '
          'em lib/config.dart.';
    }
    if (e is GoogleSignInException) {
      return 'Não foi possível entrar com o Google (${e.code.name}).';
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
          return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
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

/// O login com Google falhou por falta de configuração no Firebase.
class GoogleConfigException implements Exception {
  final String codigoNativo;
  final String codigoFirebase;

  GoogleConfigException(this.codigoNativo, this.codigoFirebase);

  @override
  String toString() => 'GoogleConfigException($codigoNativo, $codigoFirebase)';
}
