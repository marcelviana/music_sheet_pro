// lib/presentation/viewer/music_content_viewer_screen.dart
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
import 'package:music_sheet_pro/presentation/library/add_edit_music_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class MusicContentViewerScreen extends StatefulWidget {
  final String? musicId;

  const MusicContentViewerScreen({super.key, this.musicId});

  @override
  State<MusicContentViewerScreen> createState() =>
      _MusicContentViewerScreenState();
}

class _MusicContentViewerScreenState extends State<MusicContentViewerScreen>
    with BaseStateMixin, TickerProviderStateMixin {
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  final FileService _fileService = serviceLocator<FileService>();

  late final BaseStateNotifier<Music> _musicNotifier;
  late final BaseStateNotifier<List<MusicContent>> _contentsNotifier;
  late TabController _tabController;

  // Content organization
  MusicContent? _lyricsContent;
  MusicContent? _chordsContent;
  List<MusicContent> _fileContents = [];

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _musicNotifier = getNotifier<Music>('music');
    _contentsNotifier = getNotifier<List<MusicContent>>('contents');
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.musicId == null) {
      _musicNotifier.setError('ID da música não fornecido');
      return;
    }

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
      final contents =
          await _musicRepository.getContentsForMusic(widget.musicId!);

      // Organize contents
      _lyricsContent = null;
      _chordsContent = null;
      _fileContents.clear();

      for (final content in contents) {
        switch (content.type) {
          case ContentType.lyrics:
            _lyricsContent = content;
            break;
          case ContentType.chordChart:
            _chordsContent = content;
            break;
          case ContentType.sheetMusic:
          case ContentType.tablature:
            _fileContents.add(content);
            break;
        }
      }

      return contents;
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

        _showLoadingDialog('Importando arquivo...');

        try {
          final targetPath =
              await _fileService.importFile(sourcePath, widget.musicId!);

          await _musicRepository.addContent(MusicContent(
            id: const Uuid().v4(),
            musicId: widget.musicId!,
            type: ContentType.sheetMusic,
            contentPath: targetPath,
            contentText: null,
          ));

          await _loadContents();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Arquivo importado com sucesso!')),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editMusic() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditMusicScreen(music: _musicNotifier.value.data),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openPdfFile(MusicContent content) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<BaseState<Music>>(
          valueListenable: _musicNotifier,
          builder: (context, state, _) {
            return Text(state.data?.title ?? 'Música');
          },
        ),
        // ✅ REMOVE the bottom: TabBar(...) line completely
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMusic,
            tooltip: 'Editar música',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
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
                ? _buildContent(musicState.data!)
                : const SizedBox.shrink(),
          );
        },
      ),
      // ✅ ADD BOTTOM NAVIGATION INSTEAD
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lyrics),
            label: 'Letra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Cifra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Arquivos',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFile,
        child: const Icon(Icons.add),
        tooltip: 'Importar arquivo',
      ),
    );
  }

  Widget _buildContent(Music music) {
    return ValueListenableBuilder<BaseState<List<MusicContent>>>(
      valueListenable: _contentsNotifier,
      builder: (context, contentsState, _) {
        return LoadingStateWidget(
          isLoading: contentsState.isLoading,
          error: contentsState.errorMessage,
          onRetry: _loadContents,
          child: Column(
            children: [
              _buildMusicHeader(music),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _buildLyricsTab(),
                    _buildChordsTab(),
                    _buildFilesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusicHeader(Music music) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        music.artist,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                    ],
                  ),
                ),
                if (music.isFavorite)
                  const Icon(Icons.favorite, color: Colors.red),
              ],
            ),
            if (music.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
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

  Widget _buildLyricsTab() {
    if (_lyricsContent?.contentText?.isNotEmpty == true) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _lyricsContent!.contentText!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
    }

    return EmptyStateWidget(
      icon: Icons.lyrics,
      title: 'Nenhuma letra disponível',
      subtitle: 'Adicione a letra desta música para visualizá-la aqui',
      action: ElevatedButton.icon(
        onPressed: _editMusic,
        icon: const Icon(Icons.edit),
        label: const Text('Adicionar Letra'),
      ),
    );
  }

  Widget _buildChordsTab() {
    if (_chordsContent?.contentText?.isNotEmpty == true) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _chordsContent!.contentText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.8,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
    }

    return EmptyStateWidget(
      icon: Icons.music_note,
      title: 'Nenhuma cifra disponível',
      subtitle: 'Adicione a cifra desta música para visualizá-la aqui',
      action: ElevatedButton.icon(
        onPressed: _editMusic,
        icon: const Icon(Icons.edit),
        label: const Text('Adicionar Cifra'),
      ),
    );
  }

  Widget _buildFilesTab() {
    if (_fileContents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.folder_open,
        title: 'Nenhum arquivo disponível',
        subtitle: 'Importe arquivos PDF ou imagens desta música',
        action: ElevatedButton.icon(
          onPressed: _importFile,
          icon: const Icon(Icons.upload_file),
          label: const Text('Importar Arquivo'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fileContents.length,
      itemBuilder: (context, index) {
        final content = _fileContents[index];
        final fileName =
            content.contentPath?.split('/').last ?? 'Arquivo sem nome';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                content.type == ContentType.sheetMusic
                    ? Icons.picture_as_pdf
                    : Icons.grid_on,
                color: Colors.white,
              ),
            ),
            title: Text(content.type == ContentType.sheetMusic
                ? 'Partitura'
                : 'Tablatura'),
            subtitle: Text(fileName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _openPdfFile(content),
          ),
        );
      },
    );
  }
}
