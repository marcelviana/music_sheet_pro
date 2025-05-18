// lib/presentation/viewer/enhanced_pdf_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:wakelock/wakelock.dart';
import 'dart:async';

class EnhancedPdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const EnhancedPdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<EnhancedPdfViewerScreen> createState() =>
      _EnhancedPdfViewerScreenState();
}

class _EnhancedPdfViewerScreenState extends State<EnhancedPdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isLoading = true;
  bool _isNightMode = false;
  bool _isPresentationMode = false;
  bool _isFullScreen = false;
  double _currentZoom = 1.0;
  String? _error;

  // Anotações (simplificado para iniciar)
  final List<PdfAnnotation> _annotations = [];

  // Auto-scroll
  bool _isAutoScrolling = false;
  Timer? _scrollTimer;
  int _autoScrollSpeed = 2; // Pixels por segundo

  @override
  void initState() {
    super.initState();
    // Verificar se o arquivo existe
    _checkFileExists();
  }

  @override
  void dispose() {
    _stopAutoScroll(callSetState: false);
    // Garantir que a tela pode hibernar novamente
    Wakelock.disable();
    super.dispose();
  }

  Future<void> _checkFileExists() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() {
          _error = 'Arquivo não encontrado: ${widget.filePath}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao verificar arquivo: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  void _togglePresentationMode() {
    setState(() {
      _isPresentationMode = !_isPresentationMode;

      if (_isPresentationMode) {
        // Manter a tela ativa durante o modo apresentação
        Wakelock.enable();
      } else {
        // Voltar ao normal quando sair do modo apresentação
        Wakelock.disable();
        _stopAutoScroll();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _increaseZoom() {
    setState(() {
      _currentZoom += 0.25;
      _pdfViewerController.zoomLevel = _currentZoom;
    });
  }

  void _decreaseZoom() {
    setState(() {
      _currentZoom = (_currentZoom - 0.25).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _currentZoom;
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _pdfViewerController.zoomLevel = _currentZoom;
    });
  }

  void _nextPage() {
    if (_pdfViewerController.pageNumber < _pdfViewerController.pageCount) {
      _pdfViewerController.nextPage();
    }
  }

  void _previousPage() {
    if (_pdfViewerController.pageNumber > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _startAutoScroll() {
    setState(() {
      _isAutoScrolling = true;
    });

    const scrollInterval = Duration(milliseconds: 50);
    _scrollTimer = Timer.periodic(scrollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final currentOffset = _pdfViewerController.scrollOffset;
      final newOffset = Offset(
        currentOffset.dx,
        currentOffset.dy + (_autoScrollSpeed / 20),
      );
      _pdfViewerController.jumpTo(xOffset: newOffset.dx, yOffset: newOffset.dy);
    });
  }

  void _stopAutoScroll({bool callSetState = true}) {
    _scrollTimer?.cancel();
    if (!mounted) return;
    if (callSetState) {
      setState(() {
        _isAutoScrolling = false;
      });
    }
  }

  void _adjustScrollSpeed(int newSpeed) {
    setState(() {
      _autoScrollSpeed = newSpeed;
      if (_isAutoScrolling) {
        _stopAutoScroll();
        _startAutoScroll();
      }
    });
  }

  // Simplificado para iniciar
  void _addAnnotation(Offset position) {
    if (!mounted) return;
    setState(() {
      _annotations.add(
        PdfAnnotation(
          pageNumber: _pdfViewerController.pageNumber,
          position: position,
          text: 'Anotação ${_annotations.length + 1}',
          color: Colors.yellow,
        ),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anotação adicionada!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: _increaseZoom,
                  tooltip: 'Aumentar Zoom',
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: _decreaseZoom,
                  tooltip: 'Diminuir Zoom',
                ),
                IconButton(
                  icon: Icon(
                      _isNightMode ? Icons.wb_sunny : Icons.nightlight_round),
                  onPressed: _toggleNightMode,
                  tooltip: _isNightMode ? 'Modo Dia' : 'Modo Noite',
                ),
                IconButton(
                  icon: Icon(_isPresentationMode
                      ? Icons.exit_to_app
                      : Icons.slideshow),
                  onPressed: _togglePresentationMode,
                  tooltip: _isPresentationMode
                      ? 'Sair da Apresentação'
                      : 'Modo Apresentação',
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullScreen,
                  tooltip: 'Tela Cheia',
                ),
              ],
            ),
      body: _buildBody(),
      floatingActionButton:
          _isPresentationMode ? _buildPresentationFAB() : null,
      bottomNavigationBar:
          _isPresentationMode ? _buildPresentationControls() : null,
      endDrawer: _isPresentationMode ? null : _buildAnnotationsDrawer(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro ao carregar PDF: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Inversão de cores para modo noturno
        ColorFiltered(
          colorFilter: ColorFilter.matrix(_isNightMode
              ? [
                  -1,
                  0,
                  0,
                  0,
                  255,
                  0,
                  -1,
                  0,
                  0,
                  255,
                  0,
                  0,
                  -1,
                  0,
                  255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]
              : [
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
          child: GestureDetector(
            onDoubleTap: _resetZoom,
            onLongPressStart: (details) {
              if (!_isPresentationMode) {
                _addAnnotation(details.localPosition);
              }
            },
            child: SfPdfViewer.file(
              File(widget.filePath),
              key: _pdfViewerKey,
              controller: _pdfViewerController,
              onDocumentLoaded: (details) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                });
              },
              onDocumentLoadFailed: (details) {
                if (!mounted) return;
                setState(() {
                  _error = details.description;
                  _isLoading = false;
                });
              },
              // Opções para apresentação
              enableDoubleTapZooming: true,
              canShowScrollHead: !_isPresentationMode,
              canShowScrollStatus: !_isPresentationMode,
              canShowPaginationDialog: !_isPresentationMode,
              pageSpacing: _isPresentationMode ? 0 : 4,
            ),
          ),
        ),

        // Indicador de loading
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Exibir anotações
        ..._buildAnnotationMarkers(),

        // Controles de navegação extras para modo apresentação
        if (_isPresentationMode && !_isFullScreen)
          Positioned(
            bottom: 80,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'btn_prev',
                  onPressed: _previousPage,
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_pdfViewerController.pageNumber}/${_pdfViewerController.pageCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'btn_next',
                  onPressed: _nextPage,
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAnnotationMarkers() {
    return _annotations.map((annotation) {
      // Simplificado - numa implementação completa, seria necessário converter
      // a posição da anotação para coordenadas na tela
      return Positioned(
        // Posição aproximada - implementação real precisaria de cálculo
        // baseado no zoom e posição do PDF
        left: annotation.position.dx,
        top: annotation.position.dy,
        child: GestureDetector(
          onTap: () {
            // Mostrar detalhes da anotação
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Anotação'),
                content: Text(annotation.text),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: annotation.color.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.note, size: 16, color: Colors.black),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPresentationFAB() {
    return _isAutoScrolling
        ? FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: _stopAutoScroll,
            child: const Icon(Icons.stop),
          )
        : FloatingActionButton(
            onPressed: _startAutoScroll,
            child: const Icon(Icons.play_arrow),
          );
  }

  Widget _buildPresentationControls() {
    return BottomAppBar(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: _previousPage,
              tooltip: 'Página Anterior',
            ),
            Text(
              'Página ${_pdfViewerController.pageNumber} de ${_pdfViewerController.pageCount}',
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: _nextPage,
              tooltip: 'Próxima Página',
            ),
            const VerticalDivider(color: Colors.white54),
            const Text('Velocidade: ', style: TextStyle(color: Colors.white)),
            Slider(
              value: _autoScrollSpeed.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
              onChanged: (value) => _adjustScrollSpeed(value.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationsDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Center(
              child: Text(
                'Anotações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          if (_annotations.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Sem anotações.\nToque e segure no documento para adicionar.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _annotations.length,
                itemBuilder: (context, index) {
                  final annotation = _annotations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: annotation.color,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(annotation.text),
                    subtitle: Text('Página ${annotation.pageNumber}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _annotations.removeAt(index);
                        });
                      },
                    ),
                    onTap: () {
                      // Ir para a página da anotação
                      _pdfViewerController.jumpToPage(annotation.pageNumber);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nova Anotação'),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Toque e segure no documento para adicionar uma anotação',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Classe simples para armazenar anotações
class PdfAnnotation {
  final int pageNumber;
  final Offset position;
  final String text;
  final Color color;

  PdfAnnotation({
    required this.pageNumber,
    required this.position,
    required this.text,
    required this.color,
  });
}
