import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';

class PdfController extends GetxController {
  final RxList<String> folders = <String>[].obs;
  final RxList<String> pdfFiles = <String>[].obs;
  final RxList<String> filteredFiles = <String>[].obs;
  final RxList<String> _history = <String>[].obs;
  final RxInt _historyIndex = (-1).obs;
  final RxString currentFolder = ''.obs;
  final RxString currentFile = ''.obs;
  final RxInt _currentIndex = 0.obs;
  final RxDouble _zoomLevel = 1.0.obs;
  final RxList<Map<String, dynamic>> keywordSearchResults = <Map<String, dynamic>>[].obs;
  final RxString searchKeyword = ''.obs;
  final RxString keywordSearchText = ''.obs;
  Map<String, dynamic>? gtWordData;
  static const int maxHistorySize = 20;

  int get currentIndex => _currentIndex.value;
  double get zoomLevel => _zoomLevel.value;
  set zoomLevel(double value) => _zoomLevel.value = value;

  // 초기 PDF 줌 레벨을 설정하는 메서드
  void setInitialZoomLevel(double pageWidth, double pageHeight, double viewerWidth, double viewerHeight) {
    final widthRatio = viewerWidth / pageWidth;
    final heightRatio = viewerHeight / pageHeight;
    _zoomLevel.value = heightRatio < widthRatio ? heightRatio : widthRatio;
  }

  @override
  void onInit() {
    super.onInit();
    loadFolders();
    loadGtWordJson();
  }

  Future<void> loadGtWordJson() async {
    try {
      final String jsonContent = await rootBundle.loadString('assets/diagrams/GT/gt_word.json');
      gtWordData = json.decode(jsonContent);
    } catch (e) {
      print('Error loading gt_word.json: $e');
    }
  }

  Future<void> loadFolders() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final Set<String> folderSet = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/'))
          .map((String path) {
            final parts = path.split('/');
            return parts.length > 2 ? parts[2] : '';
          })
          .where((String folder) => folder.isNotEmpty)
          .toSet();
      
      folders.value = folderSet.toList();
      
      if (folders.isEmpty) {
        folders.add('GT');
      }
    } catch (e) {
      print(e);
      folders.add('GT');
    }
  }

  Future<void> loadPdfFiles(String folder) async {
    currentFolder.value = folder;
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final List<String> files = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/$folder/') && key.endsWith('.pdf'))
          .toList();
      
      pdfFiles.value = files;
      filteredFiles.value = files;
      
      // GT 폴더가 선택되었을 때 기본 PDF 파일 설정
      if (folder == 'GT' && files.isNotEmpty) {
        // TITLE 페이지를 찾아서 먼저 로드
        final titleFile = files.firstWhere(
          (file) => file.toLowerCase().contains('title'),
          orElse: () => files.firstWhere(
            (file) => file.contains('1. GTLX_GTSS ELEC DIAGRAM'),
            orElse: () => files.first,
          ),
        );
        currentFile.value = titleFile;
      }
    } catch (e) {
      print(e);
    }
  }

  void filterFiles(String keyword) {
    if (keyword.isEmpty) {
      filteredFiles.value = pdfFiles;
      return;
    }

    final lowerKeyword = keyword.toLowerCase();
    filteredFiles.value = pdfFiles.where((file) {
      final fileName = file.split('/').last.toLowerCase();
      return fileName.contains(lowerKeyword);
    }).toList();
  }

  void setCurrentFile(String file) {
    if (currentFile.value != file) {
      currentFile.value = file;
      _currentIndex.value = filteredFiles.indexOf(file);
      _addToHistory(file);
      update();
    }
  }

  void _addToHistory(String file) {
    // 현재 위치 이후의 히스토리 삭제
    if (_historyIndex.value < _history.length - 1) {
      _history.removeRange(_historyIndex.value + 1, _history.length);
    }

    // 히스토리 크기가 최대 크기를 초과하면 가장 오래된 항목 제거
    if (_history.length >= maxHistorySize) {
      _history.removeAt(0);
      _historyIndex.value = _history.length - 1;
    }

    _history.add(file);
    _historyIndex.value = _history.length - 1;
  }

  void goBack() {
    if (_historyIndex.value > 0) {
      _historyIndex.value--;
      currentFile.value = _history[_historyIndex.value];
      _currentIndex.value = filteredFiles.indexOf(currentFile.value);
      update();
    }
  }

  void goForward() {
    if (_historyIndex.value < _history.length - 1) {
      _historyIndex.value++;
      currentFile.value = _history[_historyIndex.value];
      _currentIndex.value = filteredFiles.indexOf(currentFile.value);
      update();
    }
  }

  void searchKeywords(String keyword) {
    if (gtWordData == null || keyword.isEmpty) {
      keywordSearchResults.clear();
      return;
    }

    final lowerKeyword = keyword.toLowerCase();
    final results = <Map<String, dynamic>>[];

    gtWordData!.forEach((colName, keywords) {
      if (keywords is List) {
        for (var keyword in keywords) {
          if (keyword.toString().toLowerCase().contains(lowerKeyword)) {
            results.add({
              'col_name': colName,
              'col_keyword': keyword,
            });
          }
        }
      }
    });

    keywordSearchResults.value = results;
  }
} 