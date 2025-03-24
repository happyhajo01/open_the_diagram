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
      
      final folders = manifestMap.keys
          .where((String key) => key.startsWith('assets/diagrams/'))
          .map((String key) {
            final parts = key.split('/');
            if (parts.length >= 3) {
              return parts[2]; // diagrams/폴더명/파일.pdf
            }
            return null;
          })
          .where((String? folder) => folder != null)
          .map((String folder) => folder!)
          .toSet()
          .toList();
      
      _folders = folders;
      notifyListeners();
    } catch (e) {
      print('Error loading folders: $e');
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
      
      _pdfFiles = files;
      _filteredFiles = files;
      notifyListeners();
    } catch (e) {
      print('Error loading PDF files: $e');
    }
  }

  void filterFiles(String keyword) {
    if (keyword.isEmpty) {
      _filteredFiles = _pdfFiles;
    } else {
      _filteredFiles = _pdfFiles
          .where((file) => file.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    _currentIndex = 0;
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
} 