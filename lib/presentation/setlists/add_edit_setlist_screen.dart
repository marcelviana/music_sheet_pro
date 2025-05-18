// lib/presentation/setlists/add_edit_setlist_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/setlist.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class AddEditSetlistScreen extends StatefulWidget {
  final Setlist? setlist;  // Se for null, estamos adicionando
  
  const AddEditSetlistScreen({super.key, this.setlist});

  @override
  State<AddEditSetlistScreen> createState() => _AddEditSetlistScreenState();
}

class _AddEditSetlistScreenState extends State<AddEditSetlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final SetlistRepository _setlistRepository = serviceLocator<SetlistRepository>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.setlist?.name ?? '');
    _descriptionController = TextEditingController(text: widget.setlist?.description ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveSetlist() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        if (widget.setlist == null) {
          // Adicionar nova setlist
          final setlist = Setlist(
            id: const Uuid().v4(),
            name: _nameController.text,
            description: _descriptionController.text,
          );
          
          await _setlistRepository.addSetlist(setlist);
        } else {
          // Atualizar setlist existente
          final updatedSetlist = Setlist(
            id: widget.setlist!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            createdAt: widget.setlist!.createdAt,
            updatedAt: DateTime.now(),
          );
          
          await _setlistRepository.updateSetlist(updatedSetlist);
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
        title: Text(widget.setlist == null ? 'Adicionar Setlist' : 'Editar Setlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSetlist,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.setlist == null ? 'Adicionar' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}