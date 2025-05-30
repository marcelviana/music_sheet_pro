// lib/presentation/library/add_edit_music_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:music_sheet_pro/core/services/file_service.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddEditMusicScreen extends StatefulWidget {
  final Music? music;

  const AddEditMusicScreen({super.key, this.music});

  @override
  State<AddEditMusicScreen> createState() => _AddEditMusicScreenState();
}

class _AddEditMusicScreenState extends State<AddEditMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  final FileService _fileService = serviceLocator<FileService>();

  // Music info controllers
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _tagsController;
  bool _isFavorite = false;
  bool _isLoading = false;

  // Content controllers
  late TextEditingController _lyricsController;
  late TextEditingController _chordsController;

  // Current screen
  int _currentIndex = 0;

  // Existing content (for editing)
  MusicContent? _existingLyricsContent;
  MusicContent? _existingChordsContent;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.music?.title ?? '');
    _artistController = TextEditingController(text: widget.music?.artist ?? '');
    _tagsController =
        TextEditingController(text: widget.music?.tags.join(', ') ?? '');
    _isFavorite = widget.music?.isFavorite ?? false;

    _lyricsController = TextEditingController();
    _chordsController = TextEditingController();

    // Load existing content if editing
    if (widget.music != null) {
      _loadExistingContent();
    }
  }

  Future<void> _loadExistingContent() async {
    try {
      final contents =
          await _musicRepository.getContentsForMusic(widget.music!.id);

      for (final content in contents) {
        if (content.type == ContentType.lyrics && content.contentText != null) {
          _existingLyricsContent = content;
          _lyricsController.text = content.contentText!;
        } else if (content.type == ContentType.chordChart &&
            content.contentText != null) {
          _existingChordsContent = content;
          _chordsController.text = content.contentText!;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _tagsController.dispose();
    _lyricsController.dispose();
    _chordsController.dispose();
    super.dispose();
  }

  Future<void> _saveMusic() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        String musicId;

        if (widget.music == null) {
          // Add new music
          musicId = const Uuid().v4();
          final music = Music(
            id: musicId,
            title: _titleController.text,
            artist: _artistController.text,
            tags: tags,
            isFavorite: _isFavorite,
          );

          print('🎵 Adding music: ${music.title}'); // ✅ DEBUG
          await _musicRepository.addMusic(music);
          print('✅ Music added successfully'); // ✅ DEBUG
        } else {
          // Update existing music
          musicId = widget.music!.id;
          final updatedMusic = Music(
            id: widget.music!.id,
            title: _titleController.text,
            artist: _artistController.text,
            tags: tags,
            createdAt: widget.music!.createdAt,
            updatedAt: DateTime.now(),
            isFavorite: _isFavorite,
          );

          print('🎵 Updating music: ${updatedMusic.title}'); // ✅ DEBUG
          await _musicRepository.updateMusic(updatedMusic);
          print('✅ Music updated successfully'); // ✅ DEBUG
        }

        // Save lyrics content if provided
        if (_lyricsController.text.trim().isNotEmpty) {
          print('📝 Saving lyrics content...'); // ✅ DEBUG
          if (_existingLyricsContent != null) {
            // Update existing lyrics
            final updatedContent = _existingLyricsContent!.copyWith(
              contentText: _lyricsController.text.trim(),
              updatedAt: DateTime.now(),
            );
            print(
                '📝 Updating existing lyrics: ${updatedContent.id}'); // ✅ DEBUG
            await _musicRepository.updateContent(updatedContent);
            print('✅ Lyrics updated successfully'); // ✅ DEBUG
          } else {
            // Add new lyrics
            final lyricsContent = MusicContent(
              id: const Uuid().v4(),
              musicId: musicId,
              type: ContentType.lyrics,
              contentPath: 'text_content',
              contentText: _lyricsController.text.trim(),
            );
            print(
                '📝 Adding new lyrics content: ${lyricsContent.id}'); // ✅ DEBUG
            print(
                '📝 Content text length: ${lyricsContent.contentText?.length ?? 0}'); // ✅ DEBUG
            await _musicRepository.addContent(lyricsContent);
            print('✅ Lyrics added successfully'); // ✅ DEBUG
          }
        } else if (_existingLyricsContent != null) {
          // Delete existing lyrics if now empty
          print('🗑️ Deleting existing lyrics'); // ✅ DEBUG
          await _musicRepository.deleteContent(_existingLyricsContent!.id);
        }

        // Save chords content if provided
        if (_chordsController.text.trim().isNotEmpty) {
          print('🎼 Saving chords content...'); // ✅ DEBUG
          if (_existingChordsContent != null) {
            // Update existing chords
            final updatedContent = _existingChordsContent!.copyWith(
              contentText: _chordsController.text.trim(),
              updatedAt: DateTime.now(),
            );
            print(
                '🎼 Updating existing chords: ${updatedContent.id}'); // ✅ DEBUG
            await _musicRepository.updateContent(updatedContent);
            print('✅ Chords updated successfully'); // ✅ DEBUG
          } else {
            // Add new chords
            final chordsContent = MusicContent(
              id: const Uuid().v4(),
              musicId: musicId,
              type: ContentType.chordChart,
              contentPath: 'text_content',
              contentText: _chordsController.text.trim(),
            );
            print(
                '🎼 Adding new chords content: ${chordsContent.id}'); // ✅ DEBUG
            print(
                '🎼 Content text length: ${chordsContent.contentText?.length ?? 0}'); // ✅ DEBUG
            await _musicRepository.addContent(chordsContent);
            print('✅ Chords added successfully'); // ✅ DEBUG
          }
        } else if (_existingChordsContent != null) {
          // Delete existing chords if now empty
          print('🗑️ Deleting existing chords'); // ✅ DEBUG
          await _musicRepository.deleteContent(_existingChordsContent!.id);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e, stackTrace) {
        // ✅ ADD stackTrace
        print('❌ Error saving music: $e'); // ✅ DEBUG
        print('❌ Stack trace: $stackTrace'); // ✅ DEBUG
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erro detalhado: ${e.toString()}'), // ✅ SHOW DETAILED ERROR
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5), // ✅ LONGER DURATION
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _importTextFile(bool isChords) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          if (isChords) {
            _chordsController.text = content;
          } else {
            _lyricsController.text = content;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo importado com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar arquivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.music == null ? 'Adicionar Música' : 'Editar Música'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveMusic,
              child:
                  const Text('SALVAR', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildInfoScreen(),
          _buildLyricsScreen(),
          _buildChordsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Informações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lyrics),
            label: 'Letra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Cifra',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoScreen() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Básicas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artista *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o artista';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (separadas por vírgula)',
                      border: OutlineInputBorder(),
                      helperText: 'Ex: rock, anos 80, favorita',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Favorito'),
                    subtitle: const Text('Marcar como música favorita'),
                    value: _isFavorite,
                    onChanged: (value) {
                      setState(() {
                        _isFavorite = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dicas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Use as abas "Letra" e "Cifra" para adicionar o conteúdo da música\n'
                    '• Você pode importar arquivos .txt clicando no ícone de upload\n'
                    '• O botão "SALVAR" irá salvar tudo de uma vez',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Letra da Música',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Digite ou cole a letra aqui',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _importTextFile(false),
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Importar arquivo .txt',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _lyricsController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText:
                        'Digite a letra da música aqui...\n\nVocê pode usar quebras de linha para organizar os versos.\n\nExemplo:\nVerse 1:\nTwinkle twinkle little star\nHow I wonder what you are\n\nChorus:\nUp above the world so high\nLike a diamond in the sky',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChordsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cifra e Acordes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Digite ou cole a cifra aqui',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _importTextFile(true),
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Importar arquivo .txt',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _chordsController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText:
                        'Digite a cifra aqui...\n\nExemplo:\n\nG              C\nTwinkle twinkle little star\nD              G\nHow I wonder what you are\n\nC              G\nUp above the world so high\nD              G\nLike a diamond in the sky',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
