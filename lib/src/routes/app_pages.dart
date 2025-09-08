import 'package:get/get.dart';

import '../views/editor_view.dart';

part 'app_routes.dart';

class AppPages {
  static const String initial = Routes.editor;
    
  
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.editor,
      page: () => const EditorView(),
    ),
  ];
}



