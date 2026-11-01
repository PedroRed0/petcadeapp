import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../theme/app_colors.dart';
import 'comuns.dart';

/// Foto redonda do usuário (foto do app → foto do Google → inicial do nome).
class AvatarUsuario extends StatelessWidget {
  final Usuario? usuario;
  final double raio;

  const AvatarUsuario({super.key, required this.usuario, this.raio = 34});

  static final Map<int, Uint8List> _cache = {};

  Uint8List? _bytes() {
    final foto = usuario?.foto ?? '';
    if (foto.isEmpty) return null;
    try {
      return _cache[foto.hashCode] ??= base64Decode(foto);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes();
    final url = usuario?.fotoUrl ?? '';
    final nome = usuario?.nome.trim() ?? '';
    final inicial = Text(
      nome.isEmpty ? '?' : nome[0].toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: raio * 0.75,
        fontWeight: FontWeight.w700,
        color: AppColors.destaque(context),
      ),
    );

    return CircleAvatar(
      radius: raio,
      backgroundColor: AppColors.fundoDestaque(context),
      foregroundImage: bytes != null
          ? MemoryImage(bytes)
          : (url.isNotEmpty ? NetworkImage(url) : null) as ImageProvider?,
      onForegroundImageError: bytes != null || url.isNotEmpty
          ? (_, _) {}
          : null,
      child: inicial,
    );
  }
}

/// Abre as opções (câmera / galeria / remover) e salva a nova foto.
Future<void> trocarFotoPerfil(BuildContext context, Usuario? usuario) async {
  final temFoto =
      (usuario?.foto.isNotEmpty ?? false) ||
      (usuario?.fotoUrl.isNotEmpty ?? false);

  final escolha = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, size: 20),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, size: 20),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, 'galeria'),
          ),
          if (temFoto)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.perdido,
              ),
              title: const Text(
                'Remover foto',
                style: TextStyle(color: AppColors.perdido),
              ),
              onTap: () => Navigator.pop(context, 'remover'),
            ),
        ],
      ),
    ),
  );
  if (escolha == null || !context.mounted) return;

  try {
    if (escolha == 'remover') {
      await UsuarioService().atualizarFoto(null);
      if (context.mounted) mostrarAviso(context, 'Foto removida.');
      return;
    }
    // Foto pequena e comprimida: cabe com folga no Firestore.
    final imagem = await ImagePicker().pickImage(
      source: escolha == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 70,
      preferredCameraDevice: CameraDevice.front,
    );
    if (imagem == null) return;
    await UsuarioService().atualizarFoto(await imagem.readAsBytes());
    if (context.mounted) mostrarAviso(context, 'Foto de perfil atualizada!');
  } catch (e) {
    if (context.mounted) {
      mostrarAviso(
        context,
        'Não foi possível trocar a foto: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}

/// Avatar com um botãozinho de câmera — toque para trocar a foto.
class AvatarEditavel extends StatelessWidget {
  final Usuario? usuario;
  final double raio;

  const AvatarEditavel({super.key, required this.usuario, this.raio = 34});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Trocar foto de perfil',
      child: GestureDetector(
        onTap: () => trocarFotoPerfil(context, usuario),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarUsuario(usuario: usuario, raio: raio),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.laranja,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
