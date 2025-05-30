// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/core/models/app_settings.dart';
import 'package:music_sheet_pro/core/services/settings_service.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = serviceLocator<SettingsService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _showResetDialog,
            tooltip: 'Restaurar padrões',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) {
          final settings = _settingsService.settings;
          return ListView(
            children: [
              _buildAppearanceSection(settings),
              _buildViewerSection(settings),
              _buildLibrarySection(settings),
              _buildGeneralSection(settings),
              _buildAboutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection(AppSettings settings) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aparência',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Modo escuro'),
            subtitle: const Text('Usar tema escuro'),
            value: settings.isDarkMode,
            onChanged: (value) => _settingsService.setDarkMode(value),
          ),
          ListTile(
            title: const Text('Visualização padrão'),
            subtitle: Text(settings.defaultContentView.displayName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showContentViewDialog(settings),
          ),
          SwitchListTile(
            title: const Text('Mostrar miniaturas'),
            subtitle: const Text('Exibir previews dos arquivos'),
            value: settings.showThumbnails,
            onChanged: (value) => _settingsService.setShowThumbnails(value),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerSection(AppSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Visualizador',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Zoom padrão'),
            subtitle: Text('${(settings.defaultZoomLevel * 100).toInt()}%'),
            trailing: SizedBox(
              width: 100,
              child: Slider(
                value: settings.defaultZoomLevel,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                onChanged: (value) =>
                    _settingsService.setDefaultZoomLevel(value),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Rolagem automática'),
            subtitle: const Text('Ativar por padrão'),
            value: settings.autoScrollEnabled,
            onChanged: (value) => _settingsService.setAutoScrollEnabled(value),
          ),
          if (settings.autoScrollEnabled)
            ListTile(
              title: const Text('Velocidade da rolagem'),
              subtitle: Text('Nível ${settings.autoScrollSpeed}'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: settings.autoScrollSpeed.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) =>
                      _settingsService.setAutoScrollSpeed(value.toInt()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLibrarySection(AppSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Biblioteca',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Ordenação padrão'),
            subtitle: Text(settings.defaultSortOrder.displayName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showSortOrderDialog(settings),
          ),
          ListTile(
            title: const Text('Arquivos recentes'),
            subtitle: Text('Máximo ${settings.maxRecentFiles} arquivos'),
            trailing: SizedBox(
              width: 100,
              child: Slider(
                value: settings.maxRecentFiles.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                onChanged: (value) =>
                    _settingsService.setMaxRecentFiles(value.toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(AppSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Geral',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Confirmar exclusões'),
            subtitle: const Text('Pedir confirmação antes de excluir'),
            value: settings.confirmDeleteActions,
            onChanged: (value) =>
                _settingsService.setConfirmDeleteActions(value),
          ),
          SwitchListTile(
            title: const Text('Analytics'),
            subtitle: const Text('Ajudar a melhorar o app'),
            value: settings.enableAnalytics,
            onChanged: (value) => _settingsService.setEnableAnalytics(value),
          ),
          ListTile(
            title: const Text('Exportar configurações'),
            subtitle: const Text('Salvar suas preferências'),
            leading: const Icon(Icons.download),
            onTap: _exportSettings,
          ),
          ListTile(
            title: const Text('Importar configurações'),
            subtitle: const Text('Restaurar preferências salvas'),
            leading: const Icon(Icons.upload),
            onTap: _importSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sobre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            title: Text('MusicSheet Pro'),
            subtitle: Text('Versão 1.0.0'),
            leading: Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Licenças'),
            subtitle: const Text('Ver licenças de terceiros'),
            leading: const Icon(Icons.description),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  void _showSortOrderDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenação padrão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOrder.values.map((order) {
            return RadioListTile<SortOrder>(
              title: Text(order.displayName),
              value: order,
              groupValue: settings.defaultSortOrder,
              onChanged: (value) {
                if (value != null) {
                  _settingsService.setDefaultSortOrder(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showContentViewDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visualização padrão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DefaultContentView.values.map((view) {
            return RadioListTile<DefaultContentView>(
              title: Text(view.displayName),
              value: view,
              groupValue: settings.defaultContentView,
              onChanged: (value) {
                if (value != null) {
                  _settingsService.setDefaultContentView(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar padrões'),
        content: const Text(
          'Tem certeza que deseja restaurar todas as configurações para os valores padrão?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _settingsService.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações restauradas')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    final settingsJson = _settingsService.exportSettings();
    // For now, just show the JSON. In a full implementation,
    // you'd use share_plus or file_picker to save/share the file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações exportadas'),
        content: SingleChildScrollView(
          child: SelectableText(settingsJson),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _importSettings() {
    // For now, show a text input. In a full implementation,
    // you'd use file_picker to select a file
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar configurações'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cole o JSON das configurações',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success =
                  await _settingsService.importSettings(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Configurações importadas'
                      : 'Erro ao importar'),
                  backgroundColor: success ? null : Colors.red,
                ),
              );
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}
