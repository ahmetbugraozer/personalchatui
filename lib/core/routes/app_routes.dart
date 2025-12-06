import 'package:get/get.dart';
import '../../ui/pages/auth_page.dart';
import '../../ui/pages/home_page.dart';

class AppRoutes {
  static const auth = '/auth';
  static const home = '/home';

  static final pages = [
    GetPage(
      name: auth,
      page: () => const AuthPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
