import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

enum TextoApp { termos, privacidade }

void abrirTexto(BuildContext context, TextoApp texto) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TextoScreen(texto: texto)),
  );
}

/// Termos de Uso / Política de Privacidade (textos simples, edite à vontade).
class TextoScreen extends StatelessWidget {
  final TextoApp texto;

  const TextoScreen({super.key, required this.texto});

  static const _termos = [
    (
      'Sobre o PetCadê',
      'O PetCadê é uma plataforma gratuita para divulgar animais desaparecidos e ajudar tutores a reencontrá-los.',
    ),
    (
      'Seus anúncios',
      'Você é responsável pelas informações e fotos que publica. Publique apenas animais que realmente estão desaparecidos e mantenha o anúncio atualizado, marcando como encontrado quando for o caso.',
    ),
    (
      'Confirmação de e-mail',
      'Para publicar anúncios, avisar avistamentos e denunciar, é preciso confirmar o e-mail. Isso dificulta contas falsas.',
    ),
    (
      'Denúncias',
      'Anúncios suspeitos podem ser denunciados pela bandeira no topo do anúncio. As denúncias são anônimas. Com 3 denúncias o anúncio sai das buscas até ser revisado.',
    ),
    (
      'Boa convivência',
      'Não é permitido publicar conteúdo ofensivo, falso ou que não tenha relação com animais desaparecidos. Anúncios assim podem ser removidos.',
    ),
    (
      'Recompensas',
      'Recompensas são combinadas diretamente entre o tutor e quem encontrou o animal. O PetCadê não intermedia pagamentos.',
    ),
  ];

  static const _privacidade = [
    (
      'Dados que guardamos',
      'Nome, e-mail e telefone (opcional) da sua conta, além das informações e fotos dos anúncios que você publica.',
    ),
    (
      'Como usamos',
      'Os anúncios ficam visíveis para os usuários do app, apenas com o seu primeiro nome. Seu e-mail e telefone ficam protegidos: nenhum outro usuário consegue vê-los. O telefone só é compartilhado quando você mesmo o informa ao avisar que viu um pet.',
    ),
    (
      'Bate-papo',
      'As mensagens (texto, fotos e áudios) só podem ser lidas pelas duas pessoas da conversa. No bate-papo aparecem apenas o seu nome curto (ex.: "Pedro R.") e a sua foto de perfil.',
    ),
    (
      'Localização',
      'Usamos sua localização apenas no aparelho, para mostrar a distância até os animais e marcar o local no cadastro. Ela não é salva no seu perfil.',
    ),
    (
      'Excluir dados',
      'Você pode excluir seus anúncios a qualquer momento em "Meus anúncios". Para excluir a conta, fale com a gente em Ajuda e suporte.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final termos = texto == TextoApp.termos;
    final secoes = termos ? _termos : _privacidade;

    return Scaffold(
      appBar: AppBar(
        title: Text(termos ? 'Termos de Uso' : 'Política de Privacidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          for (final (titulo, corpo) in secoes) ...[
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              corpo,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
