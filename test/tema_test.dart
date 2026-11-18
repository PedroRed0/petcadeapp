import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcade/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => themeModeNotifier.value = ThemeMode.light);

  test('modo escuro continua escuro depois de fechar e abrir o app', () async {
    SharedPreferences.setMockInitialValues({});
    await carregarTemaSalvo();
    expect(themeModeNotifier.value, ThemeMode.light);

    alternarTema(); // liga o modo escuro
    await Future<void>.delayed(Duration.zero);

    // "Fecha" o app: a memória volta ao padrão…
    themeModeNotifier.value = ThemeMode.light;
    // …e ao abrir de novo, a escolha salva é lida.
    await carregarTemaSalvo();
    expect(themeModeNotifier.value, ThemeMode.dark);
  });

  test('voltar para o claro também fica salvo', () async {
    SharedPreferences.setMockInitialValues({'modo_escuro': true});
    await carregarTemaSalvo();
    expect(themeModeNotifier.value, ThemeMode.dark);

    alternarTema();
    await Future<void>.delayed(Duration.zero);
    themeModeNotifier.value = ThemeMode.dark;
    await carregarTemaSalvo();
    expect(themeModeNotifier.value, ThemeMode.light);
  });
}
