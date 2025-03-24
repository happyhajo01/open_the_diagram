import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'controllers/pdf_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PDF Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FolderSelectionPage(),
    );
  }
}

class FolderSelectionPage extends StatelessWidget {
  const FolderSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PdfController controller = Get.put(PdfController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('폴더 선택'),
      ),
      body: Obx(() {
        if (controller.folders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: controller.folders.length,
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return ListTile(
              title: Text(folder),
              onTap: () {
                Get.to(() => const PdfViewerPage());
              },
            );
          },
        );
      }),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PdfController controller = Get.find<PdfController>();
    final TextEditingController searchController = TextEditingController();
    final LayerLink layerLink = LayerLink();
    OverlayEntry? overlayEntry;
    bool isDropdownVisible = false;

    OverlayEntry createOverlayEntry() {
      final state = Get.find<PdfController>();
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;

      return OverlayEntry(
        builder: (context) => Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: layerLink,
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
                        searchController.text = file.split('/').last.replaceAll('.pdf', '');
                        overlayEntry?.remove();
                        overlayEntry = null;
                        isDropdownVisible = false;
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

    void showOverlay() {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }

      final state = Get.find<PdfController>();
      if (state.filteredFiles.isEmpty) {
        isDropdownVisible = false;
        return;
      }

      isDropdownVisible = true;
      overlayEntry = createOverlayEntry();
      Overlay.of(context).insert(overlayEntry!);
    }

    Widget buildPdfViewer(ByteData data) {
      if (Platform.isWindows || Platform.isMacOS) {
        return Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              if (event.kind == PointerDeviceKind.mouse) {
                if (event.buttons == 0) {
                  if (event.scrollDelta.dy > 0) {
                    controller.zoomLevel += 0.1;
                  } else {
                    controller.zoomLevel -= 0.1;
                  }
                } else if (event.buttons == 1) {
                  // 스크롤 휠 클릭 시 스크롤
                }
              }
            }
          },
          child: SfPdfViewer.memory(
            data.buffer.asUint8List(),
            controller: PdfViewerController(),
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
          controller: PdfViewerController(),
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          enableHyperlinkNavigation: true,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          initialZoomLevel: 1.0,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Obx(() => Text(
              controller.currentFolder ?? 'PDF Viewer',
              style: const TextStyle(fontSize: 18),
            )),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: layerLink,
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: '검색어를 입력하세요',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        onTap: () {
                          searchController.clear();
                          showOverlay();
                        },
                        onChanged: (value) {
                          controller.filterFiles(value);
                          showOverlay();
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
              onPressed: () => controller.goBack(),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: '앞으로',
              onPressed: () => controller.goForward(),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final currentFile = controller.currentFile;
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

            return buildPdfViewer(snapshot.data!);
          },
        );
      }),
    );
  }
}
