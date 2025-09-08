import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/editor_controller.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  
  
  
  @override
  Widget build(BuildContext context) {
    Get.put(EditorController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperCoder'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.onExportPressed,
            icon: const Icon(Icons.save_alt),
            tooltip: 'Export',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Obx(() {
                  return controller.buildPlayer(context);
                }),
              ),
            ),
            const Divider(height: 1),
            Obx(() => controller.buildTimeline(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: controller.onImportPressed,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Import'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: controller.onSplitPressed,
                    icon: const Icon(Icons.content_cut),
                    label: const Text('Split'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: controller.onDeletePressed,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



