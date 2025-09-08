import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'src/routes/app_pages.dart';

void main() {
  runApp(const VideoCutEditorApp());
}

class VideoCutEditorApp extends StatelessWidget {
  const VideoCutEditorApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Cut Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
