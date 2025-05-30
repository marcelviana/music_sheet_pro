import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/presentation/setlists/add_edit_setlist_screen.dart';
import 'package:music_sheet_pro/presentation/setlists/setlist_detail_screen.dart';
import 'package:music_sheet_pro/core/widgets/loading_state_widget.dart';
import 'package:music_sheet_pro/core/widgets/empty_state_widget.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() => SetlistsScreenState();
}

class SetlistsScreenState extends State<SetlistsScreen> {
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

  Future<void> _navigateToAddSetlist() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditSetlistScreen(),
      ),
    );

    if (result == true) {
      _loadSetlists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingStateWidget(
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadSetlists,
      child: _buildSetlistsList(),
    );
  }

  Widget _buildSetlistsList() {
    if (_setlists.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.queue_music,
        title: 'Nenhuma setlist encontrada',
        subtitle: 'Crie uma setlist tocando no botão +',
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

  void addNewSetlist() {
    _navigateToAddSetlist();
  }
}
