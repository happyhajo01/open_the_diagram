import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class PdfViewerState extends ChangeNotifier {
  List<String> _folders = [];
  List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
  int _currentIndex = 0;
  List<String> _history = [];
  int _historyIndex = -1;
  String? _currentFolder;
  String? _currentFile;

  List<String> get folders => _folders;
  List<String> get pdfFiles => _pdfFiles;
  List<String> get filteredFiles => _filteredFiles;
  int get currentIndex => _currentIndex;
  String? get currentFolder => _currentFolder;
  String? get currentFile => _currentIndex >= 0 && _currentIndex < _filteredFiles.length 
      ? _filteredFiles[_currentIndex] 
      : null;

  Future<void> loadFolders() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        json.decode(manifestContent) as Map,
      );
      
      // assets/diagrams/ 폴더 아래의 모든 파일 경로를 가져옵니다
      final allPaths = manifestMap.keys.where((String key) => key.startsWith('assets/diagrams/'));
      
      // 각 경로에서 폴더 이름을 추출합니다
      final folderSet = <String>{};
      for (var path in allPaths) {
        final parts = path.split('/');
        if (parts.length >= 3) {
          folderSet.add(parts[2]); // diagrams/폴더명/파일.pdf
        }
      }
      
      if (folderSet.isEmpty) {
        // 폴더를 찾지 못한 경우 기본 폴더 추가
        folderSet.add('WBVF');
      }
      
      _folders = folderSet.toList()..sort();
      print('Found folders: $_folders'); // 디버깅을 위한 출력
      notifyListeners();
    } catch (e) {
      print('Error loading folders: $e');
      // 에러 발생 시 기본 폴더 추가
      _folders = ['WBVF'];
      notifyListeners();
    }
  }

  Future<void> setCurrentFolder(String folder) async {
    _currentFolder = folder;
    _currentIndex = 0;
    _history.clear();
    _historyIndex = -1;
    
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
      
      print('Found files in $folder: $files'); // 디버깅을 위한 출력
      _pdfFiles = files;
      _filteredFiles = files;

      // title.pdf 파일이 있다면 첫 번째로 설정
      final titleIndex = _pdfFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        // title.pdf 파일을 첫 번째로 이동
        final titleFile = _pdfFiles[titleIndex];
        _pdfFiles.removeAt(titleIndex);
        _pdfFiles.insert(0, titleFile);
        _filteredFiles = List.from(_pdfFiles);
        _currentIndex = 0; // title.pdf 파일을 선택
        print('Found title.pdf at index $titleIndex, moved to first position'); // 디버깅을 위한 출력
      }

      notifyListeners();
    } catch (e) {
      print('Error loading PDF files: $e');
    }
  }

  void filterFiles(String keyword) {
    if (keyword.isEmpty) {
      _filteredFiles = List.from(_pdfFiles);
      // title.pdf가 있다면 첫 번째로 유지
      final titleIndex = _filteredFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = _filteredFiles[titleIndex];
        _filteredFiles.removeAt(titleIndex);
        _filteredFiles.insert(0, titleFile);
        _currentIndex = 0;
      }
    } else {
      final keywordLower = keyword.toLowerCase();
      _filteredFiles = _pdfFiles
          .where((file) => file.toLowerCase().contains(keywordLower))
          .toList();
      
      // title.pdf가 검색 결과에 있다면 첫 번째로 이동
      final titleIndex = _filteredFiles.indexWhere((file) => 
          file.toLowerCase().endsWith('title.pdf'));
      if (titleIndex != -1) {
        final titleFile = _filteredFiles[titleIndex];
        _filteredFiles.removeAt(titleIndex);
        _filteredFiles.insert(0, titleFile);
        _currentIndex = 0;
      }
    }
    notifyListeners();
  }

  void nextFile() {
    if (_currentIndex < _filteredFiles.length - 1) {
      _currentIndex++;
      _addToHistory(_filteredFiles[_currentIndex]);
      notifyListeners();
    }
  }

  void previousFile() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _addToHistory(_filteredFiles[_currentIndex]);
      notifyListeners();
    }
  }

  void _addToHistory(String file) {
    _historyIndex++;
    if (_historyIndex < _history.length) {
      _history[_historyIndex] = file;
    } else {
      _history.add(file);
    }
  }

  void goBack() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _currentIndex = _filteredFiles.indexOf(_history[_historyIndex]);
      notifyListeners();
    }
  }

  void goForward() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _currentIndex = _filteredFiles.indexOf(_history[_historyIndex]);
      notifyListeners();
    }
  }

  void setCurrentFile(String file) {
    _currentFile = file;
    _currentIndex = _filteredFiles.indexOf(file);
    _addToHistory(file);
    notifyListeners();
  }
} 