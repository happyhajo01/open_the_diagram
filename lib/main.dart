import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
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
      appBar: AppBar(
        title: const Text('폴더 선택'),
      ),
      body: Consumer<PdfViewerState>(
        builder: (context, state, child) {
          if (state.folders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: state.folders.length,
            itemBuilder: (context, index) {
              final folder = state.folders[index];
              return ElevatedButton(
                onPressed: () {
                  context.read<PdfViewerState>().setCurrentFolder(folder);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PdfViewerPage(),
                    ),
                  );
                },
                child: Text(folder),
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

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '검색어를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  context.read<PdfViewerState>().filterFiles(value);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<PdfViewerState>().goBack();
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                context.read<PdfViewerState>().goForward();
              },
            ),
          ],
        ),
      ),
      body: Consumer<PdfViewerState>(
        builder: (context, state, child) {
          final currentFile = state.currentFile;
          if (currentFile == null) {
            return const Center(child: Text('PDF 파일을 선택해주세요'));
          }

          return FutureBuilder<String>(
            future: rootBundle.loadString(currentFile),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return SfPdfViewer.memory(
                Uint8List.fromList(snapshot.data!.codeUnits),
                controller: _pdfViewerController,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                enableHyperlinkNavigation: true,
                onZoomLevelChanged: (PdfZoomDetails details) {
                  // 줌 레벨 변경 시 처리
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }
}
