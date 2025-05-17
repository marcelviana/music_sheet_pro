import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/routes.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
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
  
  Future<void> _addTestMusic() async {
    try {
      final music = Music(
        id: const Uuid().v4(),
        title: "Música de Teste",
        artist: "Artista de Teste",
        tags: ["teste", "demo"],
      );
      
      await _musicRepository.addMusic(music);
      _loadMusics();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.setlists);
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestMusic,
        child: const Icon(Icons.add),
      ),
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
              onPressed: _loadMusics,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    
    if (_musics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sua biblioteca está vazia',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione músicas tocando no botão +',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addTestMusic,
              child: const Text('Adicionar música de teste'),
            ),
          ],
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
          trailing: IconButton(
            icon: Icon(
              music.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: music.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              await _musicRepository.toggleFavorite(music.id);
              _loadMusics();
            },
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