import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/music.dart';
import 'package:music_sheet_pro/core/models/music_content.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:get_it/get_it.dart';

class LyricEditorScreen extends StatefulWidget {
  final Music music;
  final MusicContent? existingContent;

  const LyricEditorScreen({required this.music, this.existingContent, Key? key})
      : super(key: key);

  @override
  State<LyricEditorScreen> createState() => _LyricEditorScreenState();
}

class _LyricEditorScreenState extends State<LyricEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  ContentType _selectedType = ContentType.lyrics;
  late final MusicRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo =
        GetIt.I.get<MusicRepository>(); // Ou instancie como faz no seu projeto
    if (widget.existingContent != null) {
      _controller.text = widget.existingContent!.contentText ?? '';
      _selectedType = widget.existingContent!.type;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final content = MusicContent(
        id: widget.existingContent?.id ?? '',
        musicId: widget.music.id,
        type: _selectedType,
        contentPath: '', // Não usado para letras/cifras
        contentText: _controller.text,
        version: widget.existingContent?.version ?? 1,
      );
      if (widget.existingContent == null) {
        await _repo.addContent(content);
      } else {
        await _repo.updateContent(content);
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingContent == null
            ? 'Adicionar Letra/Cifra'
            : 'Editar Letra/Cifra'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<ContentType>(
                value: _selectedType,
                items: [
                  DropdownMenuItem(
                      value: ContentType.lyrics, child: Text('Letra')),
                  DropdownMenuItem(
                      value: ContentType.chordChart, child: Text('Cifra')),
                ],
                onChanged: (type) {
                  if (type != null) setState(() => _selectedType = type);
                },
                decoration: InputDecoration(labelText: 'Tipo'),
              ),
              SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  minLines: 10,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Digite aqui a letra ou cifra",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? "Não pode ficar vazio"
                      : null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontFamily: "monospace"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
