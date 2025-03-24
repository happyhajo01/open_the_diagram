import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';

class PdfController extends GetxController {
  final RxList<String> _folders = <String>[].obs;
  final RxList<String> _pdfFiles = <String>[].obs;
  final RxList<String> _filteredFiles = <String>[].obs;
  final RxList<String> _history = <String>[].obs;
  final RxInt _historyIndex = (-1).obs;
  final RxString _currentFolder = ''.obs;
  final RxString _currentFile = ''.obs;
  final RxInt _currentIndex = 0.obs;
  final RxDouble _zoomLevel = 1.0.obs;

  List<String> get folders => _folders;
  List<String> get pdfFiles => _pdfFiles;
  List<String> get filteredFiles => _filteredFiles;
  String get currentFolder => _currentFolder.value;
  String get currentFile => _currentFile.value;
  int get currentIndex => _currentIndex.value;
  double get zoomLevel => _zoomLevel.value;
  set zoomLevel(double value) => _zoomLevel.value = value;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        json.decode(manifestContent) as Map,
      );
      
      final folderSet = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/'))
          .map((String key) => key.split('/')[2])
          .toSet();
      
      _folders.value = folderSet.toList();
      
      // 폴더가 없으면 기본 폴더 추가
      if (_folders.isEmpty) {
        _folders.add('WBVF');
      }
      
      // 첫 번째 폴더 자동 선택
      if (_folders.isNotEmpty) {
        setCurrentFolder(_folders.first);
      }
    } catch (e) {
      print('Error loading folders: $e');
    }
  }

  Future<void> setCurrentFolder(String folder) async {
    _currentFolder.value = folder;
    _currentIndex.value = 0;
    _history.clear();
    _historyIndex.value = -1;
    
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        json.decode(manifestContent) as Map,
      );
      
      final files = manifestMap.keys
          .where((String key) => 
              key.startsWith('assets/diagrams/$folder/') && 
              key.toLowerCase().endsWith('.pdf'))
          .toList();
      
      print('Found files in $folder: $files');
      _pdfFiles.value = files;
      _filteredFiles.value = files;

      // title.pdf 파일이 있다면 첫 번째로 설정
      final titleIndex = _pdfFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = _pdfFiles[titleIndex];
        _pdfFiles.removeAt(titleIndex);
        _pdfFiles.insert(0, titleFile);
        _filteredFiles.value = List.from(_pdfFiles);
        _currentIndex.value = 0;
        print('Found title.pdf at index $titleIndex, moved to first position');
      }

      update();
    } catch (e) {
      print('Error loading PDF files: $e');
    }
  }

  void filterFiles(String keyword) {
    if (keyword.isEmpty) {
      _filteredFiles.value = List.from(_pdfFiles);
      final titleIndex = _filteredFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = _filteredFiles[titleIndex];
        _filteredFiles.removeAt(titleIndex);
        _filteredFiles.insert(0, titleFile);
        _currentIndex.value = 0;
      }
    } else {
      final keywordLower = keyword.toLowerCase();
      _filteredFiles.value = _pdfFiles
          .where((file) => file.toLowerCase().contains(keywordLower))
          .toList();
      
      final titleIndex = _filteredFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = _filteredFiles[titleIndex];
        _filteredFiles.removeAt(titleIndex);
        _filteredFiles.insert(0, titleFile);
        _currentIndex.value = 0;
      }
    }
    update();
  }

  void setCurrentFile(String file) {
    _currentFile.value = file;
    _currentIndex.value = _filteredFiles.indexOf(file);
    _addToHistory(file);
    update();
  }

  void _addToHistory(String file) {
    // 현재 위치 이후의 히스토리 삭제
    if (_historyIndex.value < _history.length - 1) {
      _history.removeRange(_historyIndex.value + 1, _history.length);
    }
    _history.add(file);
    _historyIndex.value = _history.length - 1;
  }

  void goBack() {
    if (_historyIndex.value > 0) {
      _historyIndex.value--;
      setCurrentFile(_history[_historyIndex.value]);
    }
  }

  void goForward() {
    if (_historyIndex.value < _history.length - 1) {
      _historyIndex.value++;
      setCurrentFile(_history[_historyIndex.value]);
    }
  }
} 