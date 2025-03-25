import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pdf_controller.dart';

class FolderSelectionView extends GetView<PdfController> {
  const FolderSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('폴더 선택'),
      ),
      body: Obx(() {
        if (controller.folders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          itemCount: controller.folders.length,
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return ListTile(
              title: Text(folder),
              onTap: () {
                controller.setCurrentFolder(folder);
                Get.toNamed('/pdf-viewer');
              },
            );
          },
        );
      }),
    );
  }
} 