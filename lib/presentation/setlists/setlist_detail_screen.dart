// lib/presentation/setlists/setlist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/routes.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/presentation/setlists/add_edit_setlist_screen.dart';

class SetlistDetailScreen extends StatefulWidget {
  final String setlistId;

  const SetlistDetailScreen({super.key, required this.setlistId});

  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  final SetlistRepository _setlistRepository =
      serviceLocator<SetlistRepository>();
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();

  Setlist? _setlist;
  List<Music> _musics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSetlist();
  }

  Future<void> _loadSetlist() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final setlist = await _setlistRepository.getSetlistById(widget.setlistId);

      if (setlist == null) {
        setState(() {
          _error = 'Setlist não encontrada';
          _isLoading = false;
        });
        return;
      }

      final musics =
          await _setlistRepository.getMusicsInSetlist(widget.setlistId);

      setState(() {
        _setlist = setlist;
        _musics = musics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMusicToSetlist() async {
    // Obter todas as músicas disponíveis
    final allMusics = await _musicRepository.getAllMusics();

    // Filtrar as músicas que já estão na setlist
    final availableMusics = allMusics
        .where((music) => !_musics.any((m) => m.id == music.id))
        .toList();

    if (availableMusics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não há músicas disponíveis para adicionar')),
      );
      return;
    }

    // Mostrar diálogo para seleção de músicas
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Música'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableMusics.length,
            itemBuilder: (context, index) {
              final music = availableMusics[index];
              return ListTile(
                title: Text(music.title),
                subtitle: Text(music.artist),
                onTap: () async {
                  Navigator.pop(context);

                  try {
                    await _setlistRepository.addMusicToSetlist(widget.setlistId,
                        music.id, _musics.length // Adicionar ao final
                        );

                    _loadSetlist();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('${music.title} adicionada à setlist')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Erro ao adicionar música: ${e.toString()}')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderSetlist(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final Music item = _musics.removeAt(oldIndex);
      _musics.insert(newIndex, item);
    });

    try {
      await _setlistRepository.reorderSetlistMusics(
        widget.setlistId,
        _musics.map((m) => m.id).toList(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reordenar: ${e.toString()}')),
      );
      _loadSetlist(); // Recarregar caso haja erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_setlist?.name ?? 'Detalhes da Setlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_setlist != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditSetlistScreen(setlist: _setlist),
                  ),
                );

                if (result == true) {
                  _loadSetlist();
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_setlist_detail',
        onPressed: _addMusicToSetlist,
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
              onPressed: _loadSetlist,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_setlist == null) {
      return const Center(child: Text('Setlist não encontrada'));
    }

    if (_musics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _setlist!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _setlist!.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta setlist está vazia',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addMusicToSetlist,
              child: const Text('Adicionar Música'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_setlist!.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _setlist!.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '${_musics.length} músicas',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _musics.length,
            onReorder: _reorderSetlist,
            itemBuilder: (context, index) {
              final music = _musics[index];
              return ListTile(
                key: Key(music.id),
                title: Text(music.title),
                subtitle: Text(music.artist),
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    try {
                      await _setlistRepository.removeMusicFromSetlist(
                        widget.setlistId,
                        music.id,
                      );
                      _loadSetlist();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erro ao remover: ${e.toString()}')),
                      );
                    }
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
          ),
        ),
      ],
    );
  }
}
