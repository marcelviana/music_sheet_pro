import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';

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
      
      final contents = await _musicRepository.getContentsForMusic(widget.musicId!);
      
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
              onPressed: () {
                // TODO: Implementar adição de conteúdo
              },
              child: const Text('Adicionar conteúdo'),
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
              // TODO: Implementar visualização real
            },
            child: const Text('Abrir visualizador'),
          ),
        ],
      ),
    );
  }
}