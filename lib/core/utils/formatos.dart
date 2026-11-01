String _dd(int n) => n.toString().padLeft(2, '0');

String formatarData(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}/${d.year}';

String formatarHora(DateTime d) => '${_dd(d.hour)}:${_dd(d.minute)}';

String formatarDataHora(DateTime d) =>
    '${formatarData(d)} - ${formatarHora(d)}';

/// 850 m, 1,2 km, 12 km
String formatarDistancia(double metros) {
  if (metros < 1000) return '${(metros / 10).round() * 10} m';
  final km = metros / 1000;
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// "Há 5 min", "Há 2 h", "Há 3 dias", ou a data.
String formatarTempoRelativo(DateTime d, {DateTime? agora}) {
  final diff = (agora ?? DateTime.now()).difference(d);
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Há ${diff.inHours} h';
  if (diff.inDays < 7) {
    return diff.inDays == 1 ? 'Há 1 dia' : 'Há ${diff.inDays} dias';
  }
  return formatarData(d);
}

String primeiroNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  return partes.isEmpty ? '' : partes.first;
}
