import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:music_sheet_pro/presentation/viewer/enhanced_pdf_viewer_screen.dart';
import 'package:music_sheet_pro/presentation/lyrics/lyric_editor_screen.dart';
import 'package:music_sheet_pro/core/utils/file_utils.dart';
import 'package:music_sheet_pro/core/utils/permission_utils.dart';

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

  MusicContent? getLyricOrChordContent(List<MusicContent> contents) {
    try {
      return contents.firstWhere(
        (c) => c.type == ContentType.lyrics || c.type == ContentType.chordChart,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMusic();
  }

  Future<void> _importContent() async {
    try {
      if (!await PermissionUtils.requestFilePermissions()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de acesso aos arquivos negada.'),
            ),
          );
        }
        return;
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final fileName = result.files.single.name;

        final targetPath = await FileUtils.copyToAppDirectory(sourcePath);

        await _musicRepository.addContent(MusicContent(
          id: const Uuid().v4(),
          musicId: widget.musicId!,
          type: ContentType.sheetMusic,
          contentPath: targetPath,
          contentText: null,
        ));

        _loadMusic();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName importado com sucesso')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  }

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

    final lyricOrChordContent = getLyricOrChordContent(_contents);
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LyricEditorScreen(
                    music: _music!,
                    existingContent: lyricOrChordContent,
                  ),
                ),
              );
              if (result == true) {
                _loadMusic();
              }
            },
            child: Text(lyricOrChordContent == null
                ? 'Adicionar Letra/Cifra'
                : 'Editar Letra/Cifra'),
          ),
          if (lyricOrChordContent != null)
            SizedBox(
              height: 300,
              child: _LyricOrChordViewer(content: lyricOrChordContent),
            ),
        ],
      ),
    );
  }
}

class _LyricOrChordViewer extends StatelessWidget {
  final MusicContent content;
  const _LyricOrChordViewer({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = (content.contentText ?? '').split('\n');
    final regex = RegExp(r'(\[[^\]]+\])');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (_, idx) {
        final line = lines[idx];
        final spans = <TextSpan>[];
        int lastEnd = 0;
        for (final match in regex.allMatches(line)) {
          if (match.start > lastEnd) {
            spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
          }
          spans.add(TextSpan(
            text: match.group(0),
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ));
          lastEnd = match.end;
        }
        if (lastEnd < line.length) {
          spans.add(TextSpan(text: line.substring(lastEnd)));
        }
        return RichText(
          text: TextSpan(
            style:
                const TextStyle(color: Colors.black, fontFamily: "monospace"),
            children: spans,
          ),
        );
      },
    );
  }
}
