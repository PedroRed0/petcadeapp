import 'package:flutter/material.dart';

import '../../core/widgets/comuns.dart';
import '../../core/widgets/pet_card.dart';
import '../../models/pet.dart';
import '../../services/pet_service.dart';
import '../../services/usuario_service.dart';
import '../cadastro_pet_screen.dart';
import '../detalhes_pet_screen.dart';

class MeusAnunciosScreen extends StatefulWidget {
  const MeusAnunciosScreen({super.key});

  @override
  State<MeusAnunciosScreen> createState() => _MeusAnunciosScreenState();
}

class _MeusAnunciosScreenState extends State<MeusAnunciosScreen> {
  late final Stream<List<Pet>> _pets;
  bool _ativos = true;

  @override
  void initState() {
    super.initState();
    _pets = PetService().meusPets(UsuarioService().uid ?? '');
  }

  Future<void> _opcoes(Pet pet) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined, size: 20),
              title: const Text('Ver anúncio'),
              onTap: () => Navigator.pop(context, 'ver'),
            ),
            if (pet.perdido)
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                ),
                title: const Text('Marcar como encontrado'),
                onTap: () => Navigator.pop(context, 'encontrado'),
              )
            else
              ListTile(
                leading: const Icon(Icons.replay_rounded, size: 20),
                title: const Text('Reativar anúncio'),
                onTap: () => Navigator.pop(context, 'reativar'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, size: 20),
              title: const Text('Excluir'),
              onTap: () => Navigator.pop(context, 'excluir'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || acao == null) return;
    final servico = PetService();
    try {
      switch (acao) {
        case 'ver':
          abrirDetalhesPet(context, pet);
        case 'encontrado':
          await servico.marcarEncontrado(pet);
          if (mounted) mostrarAviso(context, 'Que ótima notícia! 🎉');
        case 'reativar':
          await servico.reativar(pet);
        case 'excluir':
          final ok = await confirmar(
            context,
            titulo: 'Excluir anúncio?',
            texto: 'O anúncio de ${pet.nome} será apagado para sempre.',
            acao: 'Excluir',
            perigo: true,
          );
          if (ok) await servico.excluir(pet);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus anúncios'),
        actions: [
          IconButton(
            tooltip: 'Novo anúncio',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CadastroPetScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Pet>>(
        stream: _pets,
        builder: (context, snap) {
          if (snap.hasError) {
            return EstadoVazio(
              icone: Icons.cloud_off_rounded,
              titulo: 'Não foi possível carregar',
              texto: '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snap.data!;
          final ativos = todos.where((p) => p.perdido).toList();
          final finalizados = todos.where((p) => !p.perdido).toList();
          final lista = _ativos ? ativos : finalizados;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Ativos (${ativos.length})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: _ativos,
                        onSelected: (_) => setState(() => _ativos = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Finalizados (${finalizados.length})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: !_ativos,
                        onSelected: (_) => setState(() => _ativos = false),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lista.isEmpty
                    ? EstadoVazio(
                        icone: _ativos
                            ? Icons.pets_rounded
                            : Icons.celebration_outlined,
                        titulo: _ativos
                            ? 'Nenhum anúncio ativo'
                            : 'Nenhum anúncio finalizado',
                        texto: _ativos
                            ? 'Toque no + para cadastrar um pet perdido.'
                            : 'Pets encontrados aparecem aqui.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => PetCard(
                          key: ValueKey(lista[i].id),
                          pet: lista[i],
                          mostrarSeta: true,
                          onTap: () => _opcoes(lista[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
