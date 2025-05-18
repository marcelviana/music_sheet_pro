import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class AddEditMusicScreen extends StatefulWidget {
  final Music? music;  // Se for null, estamos adicionando
  
  const AddEditMusicScreen({super.key, this.music});

  @override
  State<AddEditMusicScreen> createState() => _AddEditMusicScreenState();
}

class _AddEditMusicScreenState extends State<AddEditMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final MusicRepository _musicRepository = serviceLocator<MusicRepository>();
  
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _tagsController;
  bool _isFavorite = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(text: widget.music?.title ?? '');
    _artistController = TextEditingController(text: widget.music?.artist ?? '');
    _tagsController = TextEditingController(text: widget.music?.tags.join(', ') ?? '');
    _isFavorite = widget.music?.isFavorite ?? false;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _tagsController.dispose();
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
        
        if (widget.music == null) {
          // Adicionar nova música
          final music = Music(
            id: const Uuid().v4(),
            title: _titleController.text,
            artist: _artistController.text,
            tags: tags,
            isFavorite: _isFavorite,
          );
          
          await _musicRepository.addMusic(music);
        } else {
          // Atualizar música existente
          final updatedMusic = Music(
            id: widget.music!.id,
            title: _titleController.text,
            artist: _artistController.text,
            tags: tags,
            createdAt: widget.music!.createdAt,
            updatedAt: DateTime.now(),
            isFavorite: _isFavorite,
          );
          
          await _musicRepository.updateMusic(updatedMusic);
        }
        
        // Fechar a tela após salvar
        if (mounted) {
          Navigator.pop(context, true);  // Retorna true para indicar sucesso
        }
      } catch (e) {
        // Mostrar erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.music == null ? 'Adicionar Música' : 'Editar Música'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
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
                  labelText: 'Artista',
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
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Favorito'),
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMusic,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.music == null ? 'Adicionar' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}