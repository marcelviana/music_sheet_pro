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
  State<LibraryScreen> createState() => _LibraryScreenState();
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

class _LibraryScreenState extends State<LibraryScreen> {
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  final List<Music> _musics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMusics();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MusicSearchDelegate(_musicRepository),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.setlists);
            },
          ),
        ],
      ),
      body: LoadingStateWidget(
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadMusics,
        child: _buildMusicsList(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_library',
        onPressed: _navigateToAddMusic,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMusicsList() {
    if (_musics.isEmpty) {
      return EmptyStateWidget(
        // ✅ USAR NOVO WIDGET
        icon: Icons.music_note,
        title: 'Sua biblioteca está vazia',
        subtitle: 'Adicione músicas tocando no botão +',
        action: ElevatedButton(
          onPressed: _navigateToAddMusic,
          child: const Text('Adicionar música'),
        ),
      );
    }

    return ListView.builder(
      itemCount: _musics.length,
      itemBuilder: (context, index) {
        final music = _musics[index];

        return ListTile(
          title: Text(music.title),
          subtitle: Text(music.artist),
          leading: CircleAvatar(
            child: Text(music.title[0]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  music.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: music.isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  await _musicRepository.toggleFavorite(music.id);
                  _loadMusics();
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditMusicScreen(music: music),
                    ),
                  );

                  if (result == true) {
                    _loadMusics();
                  }
                },
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
        );
      },
    );
  }
}
