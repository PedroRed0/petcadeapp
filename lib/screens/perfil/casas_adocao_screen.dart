import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatos.dart';
import '../../core/widgets/comuns.dart';
import '../../services/abrigo_service.dart';
import '../../services/localizacao_service.dart';

/// "Casas de adoção próximas": abrigos de animais perto do usuário.
class CasasAdocaoScreen extends StatefulWidget {
  /// Só para testes.
  final AbrigoService? servico;

  const CasasAdocaoScreen({super.key, this.servico});

  @override
  State<CasasAdocaoScreen> createState() => _CasasAdocaoScreenState();
}

class _CasasAdocaoScreenState extends State<CasasAdocaoScreen> {
  late final AbrigoService _servico = widget.servico ?? AbrigoService();
  bool _buscando = false;
  List<Abrigo>? _abrigos; // null = ainda não buscou

  Future<void> _buscar() async {
    setState(() => _buscando = true);
    try {
      // Usa a localização que o app já tem (mais rápido); se não tiver,
      // pede ao GPS agora.
      final perto =
          LocalizacaoService.instancia.posicao.value ??
          await LocalizacaoService.instancia.atualizar();
      if (!mounted) return;
      if (perto == null) {
        mostrarAviso(
          context,
          'Permita o acesso à localização para achar casas perto de você.',
        );
        return;
      }
      final lista = await _servico.proximos(perto);
      if (mounted) setState(() => _abrigos = lista);
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          'Não foi possível buscar agora. Confira a internet e tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _abrir(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) mostrarAviso(context, 'Não foi possível abrir.');
  }

  @override
  Widget build(BuildContext context) {
    final abrigos = _abrigos;
    return Scaffold(
      appBar: AppBar(title: const Text('Casas de adoção')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fundoDestaque(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  color: AppColors.destaque(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Abrigos e ONGs perto de você que cuidam de animais '
                    'abandonados e os colocam para adoção.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _buscando ? null : _buscar,
            icon: _buscando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search_rounded, size: 20),
            label: Text(
              abrigos == null
                  ? 'Buscar casas de adoção próximas'
                  : 'Buscar de novo',
            ),
          ),
          const SizedBox(height: 20),
          if (abrigos != null && abrigos.isEmpty)
            const EstadoVazio(
              icone: Icons.search_off_rounded,
              titulo: 'Nenhuma casa de adoção encontrada perto de você',
              texto:
                  'Procuramos num raio de 80 km. Vale perguntar também em '
                  'clínicas veterinárias e na prefeitura da sua cidade.',
            ),
          if (abrigos != null)
            for (final a in abrigos) ...[
              _CartaoAbrigo(abrigo: a, onAbrir: _abrir),
              const SizedBox(height: 12),
            ],
          if (abrigos != null && abrigos.isNotEmpty)
            Text(
              'Dados dos colaboradores do OpenStreetMap. Confirme endereço e '
              'horários antes de ir.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textoSecundario,
              ),
            ),
        ],
      ),
    );
  }
}

class _CartaoAbrigo extends StatelessWidget {
  final Abrigo abrigo;
  final Future<void> Function(Uri) onAbrir;

  const _CartaoAbrigo({required this.abrigo, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final a = abrigo;
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tema.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.laranjaClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 20,
                  color: AppColors.laranja,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nome,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatarDistancia(a.distanciaMetros)} de você'
                      '${a.endereco.isNotEmpty ? ' · ${a.endereco}' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => onAbrir(a.rota),
                icon: const Icon(Icons.directions_outlined, size: 18),
                label: const Text('Como chegar'),
              ),
              if (a.telefone.isNotEmpty)
                TextButton.icon(
                  onPressed: () => onAbrir(
                    Uri(
                      scheme: 'tel',
                      path: a.telefone.replaceAll(RegExp(r'[^0-9+]'), ''),
                    ),
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Ligar'),
                ),
              if (a.site.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    final site = a.site.startsWith('http')
                        ? a.site
                        : 'https://${a.site}';
                    final uri = Uri.tryParse(site);
                    if (uri != null) onAbrir(uri);
                  },
                  icon: const Icon(Icons.public_rounded, size: 18),
                  label: const Text('Site'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
