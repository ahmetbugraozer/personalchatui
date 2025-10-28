import 'package:get/get.dart';

class SidebarController extends GetxController {
  final RxBool isOpen = true.obs;

  void toggle() => isOpen.value = !isOpen.value;

  void set(bool value) => isOpen.value = value;
}
