import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'controllers/theme_controller.dart';
import 'controllers/sidebar_controller.dart';
import 'controllers/chat_controller.dart';
import 'enums/app.enum.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Put controllers once at app start
  Get.put(ThemeController(), permanent: true);
  Get.put(SidebarController(), permanent: true);
  Get.put(ChatController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return Obx(
      () => SafeArea(
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode.value,
          initialRoute: AppRoutes.auth,
          getPages: AppRoutes.pages,
        ),
      ),
    );
  }
}
