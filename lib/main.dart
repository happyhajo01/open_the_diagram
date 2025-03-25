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
    runApp(const ExpiredApp());
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  // 가로 화면으로 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class ExpiredApp extends StatelessWidget {
  const ExpiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AlertDialog(
            title: const Text('앱 만료'),
            content: const Text('시험기간이 지났습니다.'),
            actions: [
              TextButton(
                onPressed: () => exit(0),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final controller = Get.put(PdfController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('폴더 선택'),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: controller.folders.length,
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return ListTile(
              title: Text(folder),
              onTap: () {
                controller.loadPdfFiles(folder);
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
    final controller = Get.find<PdfController>();
    final pdfViewerController = PdfViewerController();
    final LayerLink layerLink = LayerLink();
    final searchController = TextEditingController();
    OverlayEntry? overlayEntry;

    void showSearchResults(BuildContext context, RenderBox box, bool isKeywordSearch) {
      overlayEntry?.remove();
      
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: box.size.width,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: Material(
              elevation: 4,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() {
                  if (isKeywordSearch) {
                    final results = controller.keywordSearchResults;
                    if (results.isEmpty) {
                      return const ListTile(
                        title: Text('검색 결과가 없습니다'),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return ListTile(
                          title: Text(result['col_name']),
                          subtitle: Text(result['col_keyword']),
                          onTap: () {
                            final targetFile = controller.pdfFiles.firstWhere(
                              (file) => file.contains(result['col_name']),
                              orElse: () => controller.currentFile.value,
                            );
                            controller.setCurrentFile(targetFile);
                            searchController.text = targetFile.split('/').last.replaceAll('.pdf', '');
                            overlayEntry?.remove();
                            overlayEntry = null;
                          },
                        );
                      },
                    );
                  } else {
                    final files = controller.filteredFiles;
                    if (files.isEmpty) {
                      return const ListTile(
                        title: Text('검색 결과가 없습니다'),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final fileName = file.split('/').last.replaceAll('.pdf', '');
                        return ListTile(
                          title: Text(
                            fileName,
                            textAlign: TextAlign.left,
                          ),
                          onTap: () {
                            controller.setCurrentFile(file);
                            searchController.text = fileName;
                            overlayEntry?.remove();
                            overlayEntry = null;
                          },
                        );
                      },
                    );
                  }
                }),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 뷰어'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 칼럼 검색
                Expanded(
                  child: Stack(
                    children: [
                      CompositedTransformTarget(
                        link: layerLink,
                        child: TextField(
                          controller: searchController,
                          maxLength: 20,
                          decoration: InputDecoration(
                            hintText: '칼럼 검색...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            counterText: '',
                          ),
                          onChanged: (value) {
                            controller.filterFiles(value);
                            if (value.isNotEmpty) {
                              showSearchResults(context, context.findRenderObject() as RenderBox, false);
                            } else {
                              overlayEntry?.remove();
                              overlayEntry = null;
                            }
                          },
                          onTap: () {
                            if (searchController.text.isNotEmpty) {
                              showSearchResults(context, context.findRenderObject() as RenderBox, false);
                            }
                          },
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        Positioned(
                          top: 48,
                          left: 0,
                          right: 0,
                          child: Material(
                            elevation: 4,
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Obx(() {
                                final files = controller.filteredFiles;
                                if (files.isEmpty) {
                                  return const ListTile(
                                    title: Text('검색 결과가 없습니다'),
                                  );
                                }
                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: files.length,
                                  itemBuilder: (context, index) {
                                    final file = files[index];
                                    final fileName = file.split('/').last.replaceAll('.pdf', '');
                                    return ListTile(
                                      title: Text(
                                        fileName,
                                        textAlign: TextAlign.left,
                                      ),
                                      onTap: () {
                                        controller.setCurrentFile(file);
                                        searchController.text = fileName;
                                      },
                                    );
                                  },
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 키워드 검색
                Expanded(
                  child: CompositedTransformTarget(
                    link: layerLink,
                    child: TextField(
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: '키워드 검색...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        counterText: '',
                      ),
                      onChanged: (value) {
                        controller.searchKeywords(value);
                        if (value.isNotEmpty) {
                          showSearchResults(context, context.findRenderObject() as RenderBox, true);
                        } else {
                          overlayEntry?.remove();
                          overlayEntry = null;
                        }
                      },
                      onTap: () {
                        if (controller.keywordSearchResults.isNotEmpty) {
                          showSearchResults(context, context.findRenderObject() as RenderBox, true);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // PDF 뷰어
                Expanded(
                  child: Obx(() {
                    final currentFile = controller.currentFile.value;
                    if (currentFile.isEmpty) {
                      return const Center(child: Text('PDF 파일을 선택하세요'));
                    }
                    return SfPdfViewer.asset(
                      currentFile,
                      controller: pdfViewerController,
                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                        final pageSize = details.document.pages[0].size;
                        final viewerSize = MediaQuery.of(context).size;
                        controller.setInitialZoomLevel(
                          pageSize.width,
                          pageSize.height,
                          viewerSize.width, // 전체 너비 사용
                          viewerSize.height - 120, // 상단 바와 검색창 높이를 고려
                        );
                      },
                      onZoomLevelChanged: (PdfZoomDetails details) {
                        controller.zoomLevel = details.newZoomLevel;
                      },
                      initialZoomLevel: controller.zoomLevel,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
