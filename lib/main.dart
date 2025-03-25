import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'controllers/pdf_controller.dart';
import 'views/folder_selection_view.dart';
import 'views/pdf_viewer_view.dart';

void main() {
  // 만료일 체크
  final expiryDate = DateTime(2025, 4, 30);
  final now = DateTime.now();
  
  if (now.isAfter(expiryDate)) {
    runApp(const ExpiredApp());
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
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
      title: 'PDF 뷰어',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(PdfController());
      }),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const FolderSelectionView(),
        ),
        GetPage(
          name: '/pdf-viewer',
          page: () => const PdfViewerView(),
        ),
      ],
    );
  }
}
