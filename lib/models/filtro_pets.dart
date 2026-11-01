import 'package:latlong2/latlong.dart';

import 'pet.dart';

enum Ordenacao { recentes, proximos }

/// Filtros da tela "Buscar". Também é usado no mapa e nas listas.
class FiltroPets {
  final String texto;
  final String especie; // Todos, Cachorro, Gato
  final String regiao;
  final String raca; // '' = todas
  final String porte; // '' = todos
  final String sexo; // '' = todos
  final Ordenacao ordenacao;

  const FiltroPets({
    this.texto = '',
    this.especie = 'Todos',
    this.regiao = '',
    this.raca = '',
    this.porte = '',
    this.sexo = '',
    this.ordenacao = Ordenacao.recentes,
  });

  FiltroPets copyWith({
    String? texto,
    String? especie,
    String? regiao,
    String? raca,
    String? porte,
    String? sexo,
    Ordenacao? ordenacao,
  }) {
    return FiltroPets(
      texto: texto ?? this.texto,
      especie: especie ?? this.especie,
      regiao: regiao ?? this.regiao,
      raca: raca ?? this.raca,
      porte: porte ?? this.porte,
      sexo: sexo ?? this.sexo,
      ordenacao: ordenacao ?? this.ordenacao,
    );
  }

  static String _norm(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    var r = s.toLowerCase().trim();
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }
    return r;
  }

  bool aceita(Pet pet) {
    if (!pet.perdido) return false;
    if (especie != 'Todos' && pet.especie != especie) return false;
    if (porte.isNotEmpty && pet.porte != porte) return false;
    if (sexo.isNotEmpty && pet.sexo != sexo) return false;
    if (raca.isNotEmpty && _norm(pet.raca) != _norm(raca)) return false;
    if (regiao.isNotEmpty && !_norm(pet.localizacao).contains(_norm(regiao))) {
      return false;
    }
    if (texto.isNotEmpty) {
      final t = _norm(texto);
      final alvo = _norm(
        '${pet.nome} ${pet.raca} ${pet.cor} ${pet.localizacao} ${pet.especie}',
      );
      if (!alvo.contains(t)) return false;
    }
    return true;
  }

  /// Filtra e ordena. Se tiver a posição do usuário e a ordenação for
  /// "mais próximos", ordena pela distância.
  List<Pet> aplicar(List<Pet> pets, {LatLng? posicao}) {
    final lista = pets.where(aceita).toList();
    if (ordenacao == Ordenacao.proximos && posicao != null) {
      const dist = Distance();
      double d(Pet p) => p.temLocal
          ? dist.as(LengthUnit.Meter, posicao, LatLng(p.latitude, p.longitude))
          : double.infinity;
      lista.sort((a, b) => d(a).compareTo(d(b)));
    } else {
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    }
    return lista;
  }

  int get quantidadeAtivos =>
      [regiao, raca, porte, sexo].where((s) => s.isNotEmpty).length;
}
