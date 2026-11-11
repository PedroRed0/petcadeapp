import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/firebase_refs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PetCadeApp());
}

class PetCadeApp extends StatelessWidget {
  const PetCadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, modoAtual, _) {
        return MaterialApp(
          title: 'PetCadê',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: modoAtual,
          // Fonte do celular muito grande quebra o layout: limitamos a 1.3x.
          builder: envolverApp,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Aplicado a todas as telas do app:
/// - limita o zoom de fonte do sistema a 1.3x (fonte enorme quebra o layout);
/// - no Android 15+ o app é desenhado por baixo da barra de navegação
///   (◁ ○ ▢). Aqui reservamos esse espaço, para nenhum botão ficar atrás dela.
Widget envolverApp(BuildContext context, Widget? child) {
  final app = ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(
      top: false,
      left: false,
      right: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child!,
      ),
    ),
  );
  // No navegador de um computador (ou no projetor da apresentação), mostra
  // o app com largura de celular, centralizado.
  final largura = MediaQuery.sizeOf(context).width;
  if (largura <= 600) return app;
  return ColoredBox(
    color: AppColors.roxoEscuro,
    child: Center(
      child: SizedBox(
        width: 440,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(size: Size(440, MediaQuery.sizeOf(context).height)),
          child: ClipRect(child: app),
        ),
      ),
    ),
  );
}

/// Mostra o login ou o app, conforme o usuário esteja logado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Fb.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const LoginScreen();
        // A key garante que, ao trocar de conta, tudo recomece do zero.
        return MainShell(key: ValueKey(snapshot.data!.uid));
      },
    );
  }
}
