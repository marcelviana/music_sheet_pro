// lib/presentation/library/library_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/routes.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/presentation/library/add_edit_music_screen.dart';
import 'package:music_sheet_pro/core/widgets/loading_state_widget.dart';
import 'package:music_sheet_pro/core/widgets/empty_state_widget.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class MusicSearchDelegate extends SearchDelegate<String> {
  final MusicRepository _musicRepository;

  MusicSearchDelegate(this._musicRepository);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Digite para buscar músicas'),
      );
    }

    return FutureBuilder<List<Music>>(
      future: _musicRepository.searchMusics(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        final musics = snapshot.data ?? [];

        if (musics.isEmpty) {
          return const Center(child: Text('Nenhuma música encontrada'));
        }

        return ListView.builder(
          itemCount: musics.length,
          itemBuilder: (context, index) {
            final music = musics[index];
            return ListTile(
              title: Text(music.title),
              subtitle: Text(music.artist),
              leading: CircleAvatar(
                child: Text(music.title[0]),
              ),
              onTap: () {
                close(context, music.id);
                Navigator.pushNamed(
                  context,
                  AppRoutes.viewer,
                  arguments: ViewerScreenArgs(musicId: music.id),
                );
              },
            );
          },
        );
      },
    );
  }
}

class LibraryScreenState extends State<LibraryScreen> {
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  final List<Music> _musics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMusics();
  }

  // Public methods that can be called from HomeScreen
  void openSearch() {
    showSearch(
      context: context,
      delegate: MusicSearchDelegate(_musicRepository),
    );
  }

  void addNewMusic() {
    _navigateToAddMusic();
  }

  Future<void> _loadMusics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final musics = await _musicRepository.getAllMusics();

      setState(() {
        _musics.clear();
        _musics.addAll(musics);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddMusic() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditMusicScreen(),
      ),
    );

    if (result == true) {
      _loadMusics();
    }
  }

  Future<void> _deleteMusic(Music music) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deseja realmente excluir "${music.title}" de ${music.artist}?\n\n'
          'Esta ação não pode ser desfeita e todos os conteúdos associados serão removidos.',
        ),
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
        // Show loading indicator
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
                    Text('Excluindo música...'),
                  ],
                ),
              ),
            ),
          ),
        );

        await _musicRepository.deleteMusic(music.id);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Reload the list
        await _loadMusics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${music.title} foi excluída com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir música: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingStateWidget(
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadMusics,
      child: _buildMusicsList(),
    );
  }

  Widget _buildMusicsList() {
    if (_musics.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: 'Sua biblioteca está vazia',
        subtitle: 'Adicione músicas tocando no botão +',
        action: ElevatedButton(
          onPressed: _navigateToAddMusic,
          child: const Text('Adicionar música'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMusics,
      child: ListView.builder(
        itemCount: _musics.length,
        itemBuilder: (context, index) {
          final music = _musics[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(
                music.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(music.artist),
                  if (music.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: music.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              leading: CircleAvatar(
                backgroundColor: music.isFavorite ? Colors.red : null,
                child: Icon(
                  music.isFavorite ? Icons.favorite : Icons.music_note,
                  color: Colors.white,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'favorite':
                      await _musicRepository.toggleFavorite(music.id);
                      _loadMusics();
                      break;
                    case 'edit':
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditMusicScreen(music: music),
                        ),
                      );
                      if (result == true) _loadMusics();
                      break;
                    case 'delete':
                      _deleteMusic(music);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: ListTile(
                      leading: Icon(
                        music.isFavorite
                            ? Icons.favorite_border
                            : Icons.favorite,
                        color: music.isFavorite ? Colors.grey : Colors.red,
                      ),
                      title: Text(music.isFavorite
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
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
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.viewer,
                  arguments: ViewerScreenArgs(musicId: music.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
