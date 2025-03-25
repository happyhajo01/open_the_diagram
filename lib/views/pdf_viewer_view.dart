import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../controllers/pdf_controller.dart';

class PdfViewerView extends GetView<PdfController> {
  const PdfViewerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final PdfViewerController pdfViewerController = PdfViewerController();
    bool isSpacePressed = false;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            isSpacePressed = true;
          }
        } else if (event is RawKeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            isSpacePressed = false;
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 키워드 검색
                  SizedBox(
                    width: 190,
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
                      onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                          await controller.searchKeywords(value);
                        } else {
                          controller.keywordSearchResults.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 칼럼 검색
                  SizedBox(
                    width: 190,
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
                      },
                      onTap: () {
                        searchController.clear();
                        controller.filterFiles('');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            body: Obx(() {
              if (controller.currentFile.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return SfPdfViewer.asset(
                controller.currentFile.value,
                controller: pdfViewerController,
                initialZoomLevel: MediaQuery.of(context).size.height / 1000,
                onPageChanged: (PdfPageChangedDetails details) {
                  controller.currentIndex = details.newPageNumber;
                },
                onZoomLevelChanged: (PdfZoomDetails details) {
                  controller.setZoomLevel(details.newZoomLevel);
                },
              );
            }),
            bottomNavigationBar: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.goBack,
                  tooltip: '뒤로 가기',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: controller.goForward,
                  tooltip: '앞으로 가기',
                ),
              ],
            ),
          ),
          // 키워드 검색 결과
          Obx(() {
            if (controller.keywordSearchResults.isEmpty) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Material(
                elevation: 8,
                color: Colors.white,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              '키워드 검색 결과',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.keywordSearchResults.clear();
                              print('검색 결과 창 닫기'); // 디버깅용 로그
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: controller.keywordSearchResults.length,
                          itemBuilder: (context, index) {
                            final result = controller.keywordSearchResults[index];
                            return ListTile(
                              title: Text(result['col_name'] ?? ''),
                              subtitle: Text(result['col_keyword'] ?? ''),
                              onTap: () {
                                final targetFile = controller.pdfFiles.firstWhere(
                                  (file) => file.contains(result['col_name'] ?? ''),
                                  orElse: () => controller.currentFile.value,
                                );
                                controller.setCurrentFile(targetFile);
                                controller.keywordSearchResults.clear();
                                print('검색 결과 선택 및 창 닫기'); // 디버깅용 로그
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // 칼럼 검색 결과
          if (searchController.text.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Material(
                elevation: 8,
                color: Colors.white,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              '칼럼 검색 결과',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchController.clear();
                              controller.filterFiles('');
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Obx(() {
                          final files = controller.filteredFiles;
                          if (files.isEmpty) {
                            return const SizedBox.shrink();
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
                                  controller.filterFiles('');
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 