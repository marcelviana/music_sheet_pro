import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/presentation/setlists/add_edit_setlist_screen.dart';
import 'package:music_sheet_pro/presentation/setlists/setlist_detail_screen.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends State<SetlistsScreen> {
  final SetlistRepository _setlistRepository =
      serviceLocator<SetlistRepository>();
  final List<Setlist> _setlists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSetlists();
  }

  Future<void> _loadSetlists() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final setlists = await _setlistRepository.getAllSetlists();

      setState(() {
        _setlists.clear();
        _setlists.addAll(setlists);
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
        title: const Text('Setlists'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_setlists',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditSetlistScreen(),
            ),
          );

          if (result == true) {
            _loadSetlists();
          }
        },
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
              onPressed: _loadSetlists,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_setlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma setlist encontrada',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie uma setlist tocando no botão +',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _setlists.length,
      itemBuilder: (context, index) {
        final setlist = _setlists[index];

        return ListTile(
          title: Text(setlist.name),
          subtitle: Text(setlist.description),
          leading: const CircleAvatar(
            child: Icon(Icons.queue_music),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _setlistRepository.deleteSetlist(setlist.id);
              _loadSetlists();
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SetlistDetailScreen(setlistId: setlist.id),
              ),
            ).then((_) {
              _loadSetlists();
            });
          },
        );
      },
    );
  }
}
