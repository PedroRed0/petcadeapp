import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  /// Troque pelo e-mail de contato do projeto.
  static const emailSuporte = 'suporte@petcade.app';

  static const _perguntas = [
    (
      'Como cadastro um pet perdido?',
      'Toque no botão + no meio da barra inferior e siga as 4 etapas: informações, fotos, localização e confirmação.',
    ),
    (
      'Vi um pet de um anúncio. O que faço?',
      'Abra o anúncio e toque em "Eu vi este pet". Conte onde o viu e, se quiser, deixe seu telefone. O tutor recebe uma notificação.',
    ),
    (
      'Meu pet foi encontrado. Como encerro o anúncio?',
      'Vá em Perfil > Meus anúncios, toque no anúncio e escolha "Marcar como encontrado". Quem salvou o anúncio também será avisado.',
    ),
    (
      'Vi um anúncio suspeito. O que faço?',
      'Abra o anúncio e toque na bandeira no topo para denunciar. A denúncia é anônima. Nunca faça pagamentos antecipados a quem diz ter encontrado seu pet.',
    ),
    (
      'Por que preciso confirmar meu e-mail?',
      'Para evitar contas falsas, só quem confirma o e-mail pode publicar anúncios, avisar avistamentos e denunciar. Toque no aviso da tela inicial para reenviar o link.',
    ),
    (
      'Por que não vejo a distância até os pets?',
      'Permita o acesso à localização nas configurações do celular e toque em Configurações > Atualizar minha localização.',
    ),
    ('O app é pago?', 'Não. O PetCadê é totalmente gratuito.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda e suporte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          for (final (pergunta, resposta) in _perguntas)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  iconColor: AppColors.laranja,
                  title: Text(
                    pergunta,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: [
                    Text(
                      resposta,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fundoDestaque(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.destaque(context),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ainda precisa de ajuda?',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SelectableText(
                        emailSuporte,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.destaque(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
