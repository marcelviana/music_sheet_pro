// lib/presentation/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/presentation/library/library_screen.dart';
import 'package:music_sheet_pro/presentation/setlists/setlists_screen.dart';
import 'package:music_sheet_pro/presentation/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Create keys to communicate with child screens
  final GlobalKey<LibraryScreenState> _libraryKey =
      GlobalKey<LibraryScreenState>();
  final GlobalKey<SetlistsScreenState> _setlistsKey =
      GlobalKey<SetlistsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LibraryScreen(key: _libraryKey),
      SetlistsScreen(key: _setlistsKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: _getAppBarActions(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Setlists',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Biblioteca';
      case 1:
        return 'Setlists';
      default:
        return 'MusicSheet Pro';
    }
  }

  List<Widget> _getAppBarActions() {
    List<Widget> actions = [];

    if (_selectedIndex == 0) {
      // Library screen actions
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Trigger search in LibraryScreen
            _libraryKey.currentState?.openSearch();
          },
          tooltip: 'Buscar',
        ),
      ]);
    }

    // Settings button always available
    actions.add(
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
        tooltip: 'Configurações',
      ),
    );

    return actions;
  }

  Widget? _getFloatingActionButton() {
    switch (_selectedIndex) {
      case 0:
        // Library screen FAB
        return FloatingActionButton(
          heroTag: 'fab_library',
          onPressed: () {
            _libraryKey.currentState?.addNewMusic();
          },
          child: const Icon(Icons.add),
          tooltip: 'Adicionar Música',
        );
      case 1:
        // Setlists screen FAB
        return FloatingActionButton(
          heroTag: 'fab_setlists',
          onPressed: () {
            _setlistsKey.currentState?.addNewSetlist();
          },
          child: const Icon(Icons.add),
          tooltip: 'Adicionar Setlist',
        );
      default:
        return null;
    }
  }
}
