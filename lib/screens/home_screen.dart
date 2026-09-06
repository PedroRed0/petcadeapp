import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petcade/screens/animais_perdidos_screen.dart';
import 'package:petcade/screens/mapa_screen.dart';

import '../core/theme/app_colors.dart';
import 'cadastro_pet_screen.dart';
import '../core/theme/theme_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.pets_rounded, color: AppColors.laranja),
            const SizedBox(width: 8),
            Text(
              'PetCadê',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Banner principal
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.azulEscuro, AppColors.azulMedio],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reencontre seu\nmelhor amigo',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Plataforma gratuita que centraliza anúncios de animais desaparecidos com mapas e filtros por região.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Cards de ação
            _HomeActionCard(
              icon: Icons.camera_alt_rounded,
              iconBg: AppColors.laranjaClaro,
              iconColor: AppColors.laranja,
              titulo: 'Cadastrar Pet Perdido',
              subtitulo:
                  'Adicione foto, descrição, última localização e recompensa',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroPetScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _HomeActionCard(
              icon: Icons.search_rounded,
              iconBg: AppColors.laranjaClaro,
              iconColor: AppColors.laranja,
              titulo: 'Ver Todos os Casos',
              subtitulo: 'Filtros por espécie, cidade, raça e recompensa',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnimaisPerdidosScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _HomeActionCard(
              icon: Icons.map_rounded,
              iconBg: AppColors.laranjaClaro,
              iconColor: AppColors.laranja,
              titulo: 'Mapa Interativo',
              subtitulo: 'Visualize onde os pets foram vistos por último perto de você',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapaScreen()),
                );
              },
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Feito com ❤️ para os animais e suas famílias · São Paulo, 2026',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corTexto = tema.textTheme.bodyLarge?.color;
    final corFundo = tema.brightness == Brightness.dark
        ? const Color(0xFF1A1F2B)
        : Colors.white;
    final corBorda = tema.brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

    return Material(
      color: corFundo,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: corBorda),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: corTexto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.azulMedio,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
