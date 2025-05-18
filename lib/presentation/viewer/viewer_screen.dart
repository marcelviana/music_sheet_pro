import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:music_sheet_pro/presentation/viewer/enhanced_pdf_viewer_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ViewerScreen extends StatefulWidget {
  final String? musicId;

  const ViewerScreen({super.key, this.musicId});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();

  Music? _music;
  List<MusicContent> _contents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMusic();
  }

  Future<void> _importContent() async {
    try {
      // Verificar e solicitar permissões
      PermissionStatus status;

      if (Platform.isAndroid) {
        // No Android, precisamos de permissão de armazenamento
        status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();

          // Para Android 11+ (API level 30+)
          if (!status.isGranted) {
            if (await Permission.manageExternalStorage.request().isGranted) {
              status = PermissionStatus.granted;
            }
          }
        }
      } else if (Platform.isIOS) {
        // No iOS, as permissões são tratadas pelo seletor de arquivos
        status = PermissionStatus.granted;
      } else {
        // Outras plataformas
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permissão de acesso aos arquivos negada. Não é possível importar partituras.'),
            ),
          );
        }
        return;
      }

      // Agora que temos permissão, podemos selecionar o arquivo
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Obter o caminho do arquivo
        String path = result.files.single.path!;
        String fileName = result.files.single.name;

        // Adicionar o conteúdo ao repositório
        await _musicRepository.addContent(MusicContent(
          id: const Uuid().v4(),
          musicId: widget.musicId!,
          type: ContentType.sheetMusic,
          contentPath: path,
        ));

        // Recarregar a tela
        _loadMusic();

        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName importado com sucesso')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  } //_importContent

  Future<void> _loadMusic() async {
    if (widget.musicId == null) {
      setState(() {
        _error = 'ID da música não fornecido.';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final music = await _musicRepository.getMusicById(widget.musicId!);
      if (music == null) {
        setState(() {
          _error = 'Música não encontrada.';
          _isLoading = false;
        });
        return;
      }

      final contents =
          await _musicRepository.getContentsForMusic(widget.musicId!);

      setState(() {
        _music = music;
        _contents = contents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_music?.title ?? 'Visualizador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementar edição
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMusic,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_music == null) {
      return const Center(child: Text('Música não encontrada.'));
    }

    if (_contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '${_music!.title} - ${_music!.artist}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta música ainda não tem conteúdo',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _importContent,
              child: const Text('Importar Partitura'),
            ),
          ],
        ),
      );
    }

    // Exemplo simples - na implementação real, você integraria
    // com SyncfusionPdfViewer ou outra solução para visualizar partituras
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _music!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _music!.artist,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),
          const Icon(Icons.description, size: 100, color: Colors.grey),
          const SizedBox(height: 32),
          Text(
            '${_contents.length} conteúdo(s) disponível(is)',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Abrir o primeiro conteúdo na lista
              if (_contents.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedPdfViewerScreen(
                      filePath: _contents.first.contentPath,
                      title: _music!.title,
                      contentId: _contents.first.id,
                    ),
                  ),
                );
              }
            },
            child: const Text('Abrir Partitura'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _importContent,
            child: const Text('Importar Partitura'),
          ),
        ],
      ),
    );
  }
}
