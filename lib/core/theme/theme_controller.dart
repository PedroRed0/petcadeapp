import 'package:flutter/material.dart';

// Um "avisador" global e simples: quando o valor muda, quem estiver
// "escutando" ele (o MaterialApp) reconstrói a tela automaticamente.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

void alternarTema() {
  themeModeNotifier.value = themeModeNotifier.value == ThemeMode.light
      ? ThemeMode.dark
      : ThemeMode.light;
}
