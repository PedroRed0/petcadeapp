import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../services/localizacao_service.dart';
import '../services/notificacao_service.dart';
import 'buscar_screen.dart';
import 'cadastro_pet_screen.dart';
import 'home_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil/perfil_screen.dart';

/// Estrutura com a barra de navegação inferior:
/// Início · Buscar · (+) · Notificações · Perfil
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Permite que outras telas troquem de aba (ex.: sino da Home).
  static void irPara(BuildContext context, int aba) =>
      context.findAncestorStateOfType<_MainShellState>()?._trocar(aba);

  static const abaInicio = 0;
  static const abaBuscar = 1;
  static const abaNotificacoes = 2;
  static const abaPerfil = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _aba = 0;
  late final Stream<int> _naoLidas;

  @override
  void initState() {
    super.initState();
    _naoLidas = NotificacaoService().quantidadeNaoLidas();
    // Pede a localização uma vez, para mostrar as distâncias.
    LocalizacaoService.instancia.atualizar();
  }

  void _trocar(int aba) => setState(() => _aba = aba);

  void _novoAnuncio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroPetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _aba,
        children: [
          HomeScreen(naoLidas: _naoLidas),
          const BuscarScreen(),
          NotificacoesScreen(visivel: _aba == MainShell.abaNotificacoes),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _naoLidas,
        builder: (context, snap) => _BarraInferior(
          aba: _aba,
          naoLidas: snap.data ?? 0,
          onTrocar: _trocar,
          onNovo: _novoAnuncio,
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  final int aba;
  final int naoLidas;
  final ValueChanged<int> onTrocar;
  final VoidCallback onNovo;

  const _BarraInferior({
    required this.aba,
    required this.naoLidas,
    required this.onTrocar,
    required this.onNovo,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(top: BorderSide(color: tema.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(Icons.home_outlined, Icons.home_rounded, 'Início', 0),
              _item(Icons.search_rounded, Icons.search_rounded, 'Buscar', 1),
              Expanded(
                child: Center(
                  child: Material(
                    color: AppColors.laranja,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: AppColors.laranja.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onNovo,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _item(
                Icons.notifications_none_rounded,
                Icons.notifications_rounded,
                'Notificações',
                2,
                badge: naoLidas,
              ),
              _item(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    IconData icone,
    IconData iconeAtivo,
    String rotulo,
    int indice, {
    int badge = 0,
  }) {
    final ativo = aba == indice;
    final cor = ativo ? AppColors.laranja : AppColors.textoSecundario;
    return Expanded(
      child: InkWell(
        onTap: () => onTrocar(indice),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.perdido,
              label: Text('$badge'),
              child: Icon(ativo ? iconeAtivo : icone, color: cor, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
