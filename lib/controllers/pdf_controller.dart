import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';

class PdfController extends GetxController {
  final RxList<String> folders = <String>[].obs;
  final RxList<String> pdfFiles = <String>[].obs;
  final RxList<String> filteredFiles = <String>[].obs;
  final RxList<String> history = <String>[].obs;
  final RxInt _currentIndex = 0.obs;
  final RxString currentFolder = ''.obs;
  final RxString currentFile = ''.obs;
  final RxDouble _zoomLevel = 1.0.obs;
  final RxList<Map<String, String>> keywordSearchResults = <Map<String, String>>[].obs;
  final RxString searchKeyword = ''.obs;
  final RxString expiryDate = ''.obs;

  int get currentIndex => _currentIndex.value;
  set currentIndex(int value) => _currentIndex.value = value;
  
  double get zoomLevel => _zoomLevel.value;
  set zoomLevel(double value) => _zoomLevel.value = value;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
    // loadExpiryDate(); // 만료일 체크 기능 비활성화
  }

  Future<void> loadExpiryDate() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/expiry_date.json');
      final Map<String, dynamic> jsonData = Map<String, dynamic>.from(json.decode(jsonString));
      expiryDate.value = jsonData['expiry_date'] ?? '';
    } catch (e) {
      print('만료일 로드 실패: $e');
      expiryDate.value = ''; // 오류 발생 시 빈 문자열로 설정
    }
  }

  Future<void> loadFolders() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final Set<String> folderSet = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/'))
          .map((String key) => key.split('/')[2])
          .toSet();
      
      folders.value = folderSet.toList()..sort();
      
      if (folders.isEmpty) {
        folders.add('WBVF');
      }
      
      if (folders.isNotEmpty) {
        setCurrentFolder(folders.first);
      }
    } catch (e) {
      print('폴더 로드 실패: $e');
    }
  }

  Future<void> loadPdfFiles(String folder) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      pdfFiles.value = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/$folder/') && key.endsWith('.pdf'))
          .toList()
        ..sort();
      
      final titleIndex = pdfFiles.indexWhere((file) => file.contains('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = pdfFiles.removeAt(titleIndex);
        pdfFiles.insert(0, titleFile);
      }
      
      if (pdfFiles.isNotEmpty) {
        setCurrentFile(pdfFiles.first);
      }
    } catch (e) {
      print('PDF 파일 로드 실패: $e');
    }
  }

  void setCurrentFolder(String folder) {
    currentFolder.value = folder;
    loadPdfFiles(folder);
  }

  void setCurrentFile(String file) {
    currentFile.value = file;
    history.add(file);
    currentIndex = history.length - 1;
  }

  void filterFiles(String keyword) {
    if (keyword.isEmpty) {
      filteredFiles.value = pdfFiles;
      return;
    }
    
    filteredFiles.value = pdfFiles
        .where((file) => file.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
    
    final titleIndex = filteredFiles.indexWhere((file) => file.contains('title.pdf'));
    if (titleIndex != -1) {
      final titleFile = filteredFiles.removeAt(titleIndex);
      filteredFiles.insert(0, titleFile);
    }
  }

  Future<void> searchKeywords(String keyword) async {
    if (keyword.isEmpty) {
      keywordSearchResults.clear();
      return;
    }

    try {
      print('=== 키워드 검색 시작 ===');
      print('검색어: $keyword');
      
      final String jsonString = await rootBundle.loadString('assets/diagrams/GT/gt_word.json');
      print('JSON 파일 로드 성공');
      
      final List<dynamic> jsonData = json.decode(jsonString);
      print('JSON 데이터 파싱 성공');
      print('JSON 데이터 개수: ${jsonData.length}');
      
      final List<Map<String, String>> results = [];
      
      for (var item in jsonData) {
        if (item is Map<String, dynamic>) {
          final colName = item['col_name'] as String?;
          final colKeywords = item['col_keyword'] as List<dynamic>?;
          
          print('검사 중인 항목: $colName');
          print('키워드 목록: $colKeywords');
          
          if (colName != null && colKeywords != null) {
            for (var keywordItem in colKeywords) {
              print('비교 중인 키워드: $keywordItem');
              if (keywordItem.toString().toLowerCase().contains(keyword.toLowerCase())) {
                print('일치하는 키워드 발견: $keywordItem');
                results.add({
                  'col_name': colName,
                  'col_keyword': keywordItem.toString(),
                });
                break; // 한 항목에서 찾으면 다음 항목으로 이동
              }
            }
          }
        }
      }
      
      print('검색 결과 개수: ${results.length}');
      print('검색 결과: $results');
      
      keywordSearchResults.value = results;
      print('keywordSearchResults 업데이트됨: ${keywordSearchResults.value}');
      print('=== 키워드 검색 완료 ===');
    } catch (e) {
      print('키워드 검색 오류: $e');
      print('에러 스택 트레이스: ${StackTrace.current}');
      keywordSearchResults.clear();
    }
  }

  void goBack() {
    if (currentIndex > 0) {
      currentIndex--;
      currentFile.value = history[currentIndex];
    }
  }

  void goForward() {
    if (currentIndex < history.length - 1) {
      currentIndex++;
      currentFile.value = history[currentIndex];
    }
  }

  void setZoomLevel(double level) {
    zoomLevel = level;
  }
} 