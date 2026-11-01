import 'package:flutter/material.dart';

import '../../core/widgets/comuns.dart';
import '../../core/widgets/pet_card.dart';
import '../../models/pet.dart';
import '../../models/usuario.dart';
import '../../services/pet_service.dart';
import '../../services/usuario_service.dart';
import '../detalhes_pet_screen.dart';

class AnimaisSalvosScreen extends StatefulWidget {
  const AnimaisSalvosScreen({super.key});

  @override
  State<AnimaisSalvosScreen> createState() => _AnimaisSalvosScreenState();
}

class _AnimaisSalvosScreenState extends State<AnimaisSalvosScreen> {
  late final Stream<Usuario?> _usuario;
  late final Stream<List<Pet>> _pets;

  @override
  void initState() {
    super.initState();
    _usuario = UsuarioService().usuarioAtual();
    _pets = PetService().listarPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animais salvos')),
      body: StreamBuilder<Usuario?>(
        stream: _usuario,
        builder: (context, snapU) => StreamBuilder<List<Pet>>(
          stream: _pets,
          builder: (context, snapP) {
            if (!snapU.hasData || !snapP.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final ids = snapU.data!.favoritos.toSet();
            final pets = snapP.data!.where((p) => ids.contains(p.id)).toList();
            if (pets.isEmpty) {
              return const EstadoVazio(
                icone: Icons.favorite_border_rounded,
                titulo: 'Nenhum animal salvo',
                texto: 'Toque no coração de um anúncio para acompanhá-lo aqui.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => PetCard(
                key: ValueKey(pets[i].id),
                pet: pets[i],
                onTap: () => abrirDetalhesPet(context, pets[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}
