// lib/presentation/viewer/improved_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/core/services/file_service.dart';
import 'package:music_sheet_pro/core/state/base_state.dart';
import 'package:music_sheet_pro/core/widgets/loading_state_widget.dart';
import 'package:music_sheet_pro/core/widgets/empty_state_widget.dart';
import 'package:music_sheet_pro/presentation/viewer/enhanced_pdf_viewer_screen.dart';
import 'package:music_sheet_pro/presentation/lyrics/lyric_editor_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class ImprovedViewerScreen extends StatefulWidget {
  final String? musicId;

  const ImprovedViewerScreen({super.key, this.musicId});

  @override
  State<ImprovedViewerScreen> createState() => _ImprovedViewerScreenState();
}

class _ImprovedViewerScreenState extends State<ImprovedViewerScreen>
    with BaseStateMixin {
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  final FileService _fileService = serviceLocator<FileService>();

  late final BaseStateNotifier<Music> _musicNotifier;
  late final BaseStateNotifier<List<MusicContent>> _contentsNotifier;

  @override
  void initState() {
    super.initState();
    _musicNotifier = getNotifier<Music>('music');
    _contentsNotifier = getNotifier<List<MusicContent>>('contents');
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.musicId == null) {
      _musicNotifier.setError('ID da música não fornecido');
      return;
    }

    // Load music and contents in parallel
    await Future.wait([
      _loadMusic(),
      _loadContents(),
    ]);
  }

  Future<void> _loadMusic() async {
    await _musicNotifier.execute(() async {
      final music = await _musicRepository.getMusicById(widget.musicId!);
      if (music == null) {
        throw Exception('Música não encontrada');
      }
      return music;
    });
  }

  Future<void> _loadContents() async {
    await _contentsNotifier.execute(() async {
      return await _musicRepository.getContentsForMusic(widget.musicId!);
    });
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result?.files.single.path != null) {
        final sourcePath = result!.files.single.path!;

        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Importando arquivo...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        try {
          // Import file
          final targetPath =
              await _fileService.importFile(sourcePath, widget.musicId!);

          // Add to database
          await _musicRepository.addContent(MusicContent(
            id: const Uuid().v4(),
            musicId: widget.musicId!,
            type: ContentType.sheetMusic,
            contentPath: targetPath,
            contentText: null,
          ));

          // Reload contents
          await _loadContents();

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Arquivo importado com sucesso!')),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao importar: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar arquivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openContent(MusicContent content) async {
    if (content.type == ContentType.sheetMusic) {
      if (content.contentPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caminho do arquivo não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!await _fileService.fileExists(content.contentPath!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedPdfViewerScreen(
            filePath: content.contentPath!,
            title: _musicNotifier.value.data?.title ?? 'Documento',
            contentId: content.id,
          ),
        ),
      );
    } else {
      // Open lyric/chord editor
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LyricEditorScreen(
            music: _musicNotifier.value.data!,
            existingContent: content,
          ),
        ),
      );

      // Reload if edited
      if (result == true) {
        _loadContents();
      }
    }
  }

  Future<void> _deleteContent(MusicContent content) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este conteúdo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from database
        await _musicRepository.deleteContent(content.id);

        // Delete file if it's a file-based content
        if (content.type == ContentType.sheetMusic &&
            content.contentPath?.isNotEmpty == true) {
          try {
            await File(content.contentPath!).delete();
          } catch (e) {
            // File might not exist, continue anyway
          }
        }

        // Reload contents
        await _loadContents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conteúdo excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<BaseState<Music>>(
          valueListenable: _musicNotifier,
          builder: (context, state, _) {
            return Text(state.data?.title ?? 'Visualizador');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ValueListenableBuilder<BaseState<Music>>(
        valueListenable: _musicNotifier,
        builder: (context, musicState, _) {
          return LoadingStateWidget(
            isLoading: musicState.isLoading,
            error: musicState.errorMessage,
            onRetry: _loadMusic,
            child: musicState.data != null
                ? _buildMusicContent(musicState.data!)
                : const SizedBox.shrink(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFile,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMusicContent(Music music) {
    return ValueListenableBuilder<BaseState<List<MusicContent>>>(
      valueListenable: _contentsNotifier,
      builder: (context, contentsState, _) {
        return LoadingStateWidget(
          isLoading: contentsState.isLoading,
          error: contentsState.errorMessage,
          onRetry: _loadContents,
          child: contentsState.data != null
              ? _buildContentsList(music, contentsState.data!)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContentsList(Music music, List<MusicContent> contents) {
    if (contents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: '${music.title} - ${music.artist}',
        subtitle: 'Esta música ainda não tem conteúdo',
        action: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _importFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar Arquivo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LyricEditorScreen(
                      music: music,
                      existingContent: null,
                    ),
                  ),
                );
                if (result == true) _loadContents();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Adicionar Letra/Cifra'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length + 1, // +1 for header
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildMusicHeader(music);
        }

        final content = contents[index - 1];
        return _buildContentCard(content);
      },
    );
  }

  Widget _buildMusicHeader(Music music) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              music.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              music.artist,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (music.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: music.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(MusicContent content) {
    IconData icon;
    String typeLabel;
    Color? color;

    switch (content.type) {
      case ContentType.lyrics:
        icon = Icons.lyrics;
        typeLabel = 'Letra';
        color = Colors.blue;
        break;
      case ContentType.chordChart:
        icon = Icons.music_note;
        typeLabel = 'Cifra';
        color = Colors.green;
        break;
      case ContentType.tablature:
        icon = Icons.grid_on;
        typeLabel = 'Tablatura';
        color = Colors.orange;
        break;
      case ContentType.sheetMusic:
        icon = Icons.picture_as_pdf;
        typeLabel = 'Partitura';
        color = Colors.red;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(typeLabel),
        subtitle: content.contentText != null
            ? Text(
                content.contentText!.length > 50
                    ? '${content.contentText!.substring(0, 50)}...'
                    : content.contentText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                'Arquivo: ${content.contentPath?.split('/').last ?? 'Sem nome'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteContent(content);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _openContent(content),
      ),
    );
  }
}
