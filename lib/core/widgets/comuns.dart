import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Campo de busca cinza e arredondado.
class CampoBusca extends StatelessWidget {
  final String dica;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool somenteLeitura;

  const CampoBusca({
    super.key,
    this.dica = 'Buscar por nome, raça, cidade...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.somenteLeitura = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: somenteLeitura,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: dica,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: tema.colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: AppColors.destaque(context)),
        ),
      ),
    );
  }
}

/// Linha de opções: Todos / Cães / Gatos.
class FiltroEspecie extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  static const opcoes = {'Todos': 'Todos', 'Cachorro': 'Cães', 'Gato': 'Gatos'};

  const FiltroEspecie({super.key, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: opcoes.entries
          .map(
            (e) => ChoiceChip(
              label: Text(e.value),
              selected: valor == e.key,
              onSelected: (_) => onChanged(e.key),
            ),
          )
          .toList(),
    );
  }
}

/// Mensagem centralizada para listas vazias / erros.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? texto;
  final Widget? acao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fundoDestaque(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 26, color: AppColors.destaque(context)),
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (texto != null) ...[
              const SizedBox(height: 4),
              Text(
                texto!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}

/// Item de menu: ícone, título, subtítulo e seta (Perfil, Buscar).
class LinhaOpcao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onTap;
  final Color? cor;
  final Widget? trailing;
  final bool comBorda;

  const LinhaOpcao({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
    this.onTap,
    this.cor,
    this.trailing,
    this.comBorda = true,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corIcone = cor ?? AppColors.destaque(context);
    final conteudo = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: corIcone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, size: 19, color: corIcone),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cor ?? tema.colorScheme.onSurface,
                ),
              ),
              if (subtitulo != null && subtitulo!.isNotEmpty)
                Text(
                  subtitulo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
            ],
          ),
        ),
        trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textoSecundario,
            ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: comBorda
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tema.colorScheme.outline),
              )
            : null,
        child: conteudo,
      ),
    );
  }
}

/// Título de seção com ação opcional à direita ("Ver todos").
class TituloSecao extends StatelessWidget {
  final String titulo;
  final String? acao;
  final VoidCallback? onAcao;

  const TituloSecao({super.key, required this.titulo, this.acao, this.onAcao});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (acao != null)
          GestureDetector(
            onTap: onAcao,
            child: Text(
              acao!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.laranja,
              ),
            ),
          ),
      ],
    );
  }
}

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Abre uma janela que sobe de baixo (bottom sheet) sem ficar atrás
/// da barra de navegação do Android (◁ ○ ▢) nem do "notch".
Future<T?> abrirJanela<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    builder: (context) => SafeArea(top: false, child: builder(context)),
  );
}
