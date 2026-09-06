import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, modoAtual, _) {
        final escuro = modoAtual == ThemeMode.dark;
        return IconButton(
          icon: Icon(
            escuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
          onPressed: alternarTema,
          tooltip: escuro ? 'Modo claro' : 'Modo escuro',
        );
      },
    );
  }
}
