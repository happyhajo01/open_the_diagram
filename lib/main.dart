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
                  child: TextField(
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
                    onChanged: controller.filterFiles,
                  ),
                ),
                const SizedBox(width: 8),
                // 키워드 검색
                Expanded(
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
                    onChanged: controller.searchKeywords,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // 파일 목록
                Expanded(
                  flex: 1,
                  child: Obx(() {
                    final files = controller.filteredFiles;
                    return ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final fileName = file.split('/').last.replaceAll('.pdf', '');
                        return ListTile(
                          title: Text(fileName),
                          onTap: () {
                            controller.currentFile.value = file;
                          },
                        );
                      },
                    );
                  }),
                ),
                // 키워드 검색 결과
                Expanded(
                  flex: 1,
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: controller.keywordSearchResults.length,
                      itemBuilder: (context, index) {
                        final result = controller.keywordSearchResults[index];
                        return ListTile(
                          title: Text(result['col_name']),
                          subtitle: Text(result['col_keyword']),
                          onTap: () {
                            // 해당 칼럼으로 이동
                            controller.currentFile.value = controller.pdfFiles.firstWhere(
                              (file) => file.contains(result['col_name']),
                              orElse: () => controller.currentFile.value,
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
                // PDF 뷰어
                Expanded(
                  flex: 3,
                  child: Obx(() {
                    final currentFile = controller.currentFile.value;
                    if (currentFile.isEmpty) {
                      return const Center(child: Text('PDF 파일을 선택하세요'));
                    }
                    return SfPdfViewer.asset(
                      currentFile,
                      controller: pdfViewerController,
                      onZoomLevelChanged: (PdfZoomDetails details) {
                        controller.zoomLevel = details.newZoomLevel;
                      },
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
