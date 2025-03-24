import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'pdf_viewer_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PdfViewerState(),
      child: MaterialApp(
        title: 'PDF 뷰어',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const FolderSelectionPage(),
      ),
    );
  }
}

class FolderSelectionPage extends StatefulWidget {
  const FolderSelectionPage({super.key});

  @override
  State<FolderSelectionPage> createState() => _FolderSelectionPageState();
}

class _FolderSelectionPageState extends State<FolderSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PdfViewerState>().loadFolders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PdfViewerState>(
        builder: (context, state, child) {
          if (state.folders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.folders.length,
            itemBuilder: (context, index) {
              final folder = state.folders[index];
              return Card(
                child: ListTile(
                  title: Text(folder),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.read<PdfViewerState>().setCurrentFolder(folder);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PdfViewerPage(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final TextEditingController _searchController = TextEditingController();
  late PdfViewerController _pdfViewerController;
  bool _isScrolling = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _showOverlay() {
    _removeOverlay();
    final state = context.read<PdfViewerState>();
    if (state.filteredFiles.isEmpty) {
      _isDropdownVisible = false;
      return;
    }

    _isDropdownVisible = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final state = context.read<PdfViewerState>();
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.4,
              ),
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: state.filteredFiles.length,
                itemBuilder: (context, index) {
                  final file = state.filteredFiles[index];
                  return ListTile(
                    title: Text(file.split('/').last.replaceAll('.pdf', '')),
                    onTap: () {
                      state.setCurrentFile(file);
                      _searchController.text = file.split('/').last.replaceAll('.pdf', '');
                      _removeOverlay();
                      _isDropdownVisible = false;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer(ByteData data) {
    if (Platform.isWindows || Platform.isMacOS) {
      return Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent) {
            if (event.kind == PointerDeviceKind.mouse) {
              if (event.buttons == 0) {
                // 스크롤 휠만 사용 시 줌 인/아웃
                if (event.scrollDelta.dy > 0) {
                  _pdfViewerController.zoomLevel += 0.1;
                } else {
                  _pdfViewerController.zoomLevel -= 0.1;
                }
              } else if (event.buttons == 1) {
                // 스크롤 휠 클릭 시 스크롤
                _isScrolling = true;
              }
            }
          }
        },
        onPointerUp: (PointerUpEvent event) {
          _isScrolling = false;
        },
        child: SfPdfViewer.memory(
          data.buffer.asUint8List(),
          controller: _pdfViewerController,
          enableDoubleTapZooming: false,
          enableTextSelection: true,
          enableHyperlinkNavigation: true,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          initialZoomLevel: 1.0,
        ),
      );
    } else {
      return SfPdfViewer.memory(
        data.buffer.asUint8List(),
        controller: _pdfViewerController,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        enableHyperlinkNavigation: true,
        pageLayoutMode: PdfPageLayoutMode.single,
        scrollDirection: PdfScrollDirection.horizontal,
        initialZoomLevel: 1.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Consumer<PdfViewerState>(
              builder: (context, state, child) {
                return Text(
                  state.currentFolder ?? 'PDF Viewer',
                  style: const TextStyle(fontSize: 18),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: '검색어를 입력하세요',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        onTap: () {
                          _searchController.clear();
                          _showOverlay();
                        },
                        onChanged: (value) {
                          final state = context.read<PdfViewerState>();
                          state.filterFiles(value);
                          _showOverlay();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: '뒤로',
              onPressed: () {
                context.read<PdfViewerState>().goBack();
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: '앞으로',
              onPressed: () {
                context.read<PdfViewerState>().goForward();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<PdfViewerState>(
              builder: (context, state, child) {
                final currentFile = state.currentFile;
                if (currentFile == null) {
                  return const Center(child: Text('PDF 파일을 선택해주세요'));
                }

                return FutureBuilder<ByteData>(
                  future: rootBundle.load(currentFile),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _buildPdfViewer(snapshot.data!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }
}
