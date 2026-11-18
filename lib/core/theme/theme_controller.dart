import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Um "avisador" global e simples: quando o valor muda, quem estiver
// "escutando" ele (o MaterialApp) reconstrói a tela automaticamente.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

// Nome da "gaveta" onde a escolha fica guardada no aparelho.
const _chaveModoEscuro = 'modo_escuro';

/// Lê a escolha salva no aparelho. Chamado uma vez, ao abrir o app.
Future<void> carregarTemaSalvo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final escuro = prefs.getBool(_chaveModoEscuro) ?? false;
    themeModeNotifier.value = escuro ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {
    // Se não der para ler (ex.: navegador em modo anônimo), abre no claro.
  }
}

void alternarTema() {
  final novo = themeModeNotifier.value == ThemeMode.light
      ? ThemeMode.dark
      : ThemeMode.light;
  themeModeNotifier.value = novo;
  _salvarTema(novo);
}

Future<void> _salvarTema(ThemeMode modo) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveModoEscuro, modo == ThemeMode.dark);
  } catch (_) {
    // Não salvar não deve travar o app: o tema só não é lembrado.
  }
}
