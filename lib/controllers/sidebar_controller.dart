import 'package:get/get.dart';

class SidebarController extends GetxController {
  final RxBool isOpen = true.obs;

  void toggle() => isOpen.value = !isOpen.value;

  void set(bool value) => isOpen.value = value;

  /// Auto-collapse sidebar when screen becomes narrow
  void autoCollapseIfNarrow(double screenWidth, {double breakpoint = 700}) {
    if (screenWidth < breakpoint && isOpen.value) {
      isOpen.value = false;
    }
  }
}
