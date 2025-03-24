import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'controllers/pdf_controller.dart';

void main() {
  // 만료일 체크
  final expiryDate = DateTime(2025, 4, 30);
  final now = DateTime.now();
  
  if (now.isAfter(expiryDate)) {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('앱 만료'),
        content: const Text('시험기간이 지났습니다.'),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();
  // 가로 화면으로 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
        title: const Text('기종을 선택하세요'),
      ),
      body: Obx(() {
        if (controller.folders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.folders.length,
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return ElevatedButton(
              onPressed: () {
                controller.setCurrentFolder(folder);
                Get.to(() => const PdfViewerPage());
              },
              child: Text(
                folder,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
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
      final PdfController controller = Get.find<PdfController>();
      final PdfViewerController pdfViewerController = PdfViewerController();
      
      if (Platform.isWindows || Platform.isMacOS) {
        return Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              if (event.kind == PointerDeviceKind.mouse) {
                if (event.buttons == 0) {
                  if (event.scrollDelta.dy > 0) {
                    pdfViewerController.zoomLevel += 0.1;
                  } else {
                    pdfViewerController.zoomLevel -= 0.1;
                  }
                } else if (event.buttons == 1) {
                  // 스크롤 휠 클릭 시 스크롤
                }
              }
            }
          },
          child: SfPdfViewer.memory(
            data.buffer.asUint8List(),
            controller: pdfViewerController,
            onZoomLevelChanged: (PdfZoomDetails details) {
              controller.zoomLevel = details.newZoomLevel;
            },
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
          onZoomLevelChanged: (PdfZoomDetails details) {
            controller.zoomLevel = details.newZoomLevel;
          },
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(controller.currentFolder),
            const SizedBox(width: 16),
            CompositedTransformTarget(
              link: layerLink,
              child: SizedBox(
                width: 300,
                child: TextField(
                  controller: searchController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    hintText: '파일 검색...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    controller.filterFiles(value);
                    showOverlay();
                  },
                  onTap: () {
                    searchController.clear();
                    controller.filterFiles('');
                    showOverlay();
                  },
                  onSubmitted: (value) {
                    overlayEntry?.remove();
                    overlayEntry = null;
                    isDropdownVisible = false;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() => Stack(
        children: [
          FutureBuilder<ByteData>(
            future: rootBundle.load(controller.currentFile),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return buildPdfViewer(snapshot.data!);
            },
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: controller.goBack,
                  tooltip: '뒤로 가기',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  onPressed: controller.goForward,
                  tooltip: '앞으로 가기',
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
