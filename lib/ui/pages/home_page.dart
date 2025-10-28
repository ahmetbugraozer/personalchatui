import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/sidebar_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../enums/app.enum.dart';
import '../widgets/sidebar_panel.dart';
import '../widgets/chat_area.dart';
import '../dialogs/premium_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final sidebar = Get.find<SidebarController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        // Auto-collapse on very narrow screens
        if (isNarrow && sidebar.isOpen.value) {
          sidebar.set(false);
        }

        // Keep this in sync with PreferredSize height below
        final double appBarHeight = (7.2.h).clamp(56.0, 72.0);
        final double topSafe = MediaQuery.of(context).padding.top;
        final double contentTopPadding = topSafe + appBarHeight;

        return Scaffold(
          // Allow body to go behind the app bar so SidebarPanel reaches the top
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(appBarHeight),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.0.w),
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    // Sidebar toggle (visible on narrow screens)
                    if (isNarrow)
                      Builder(
                        // Use a Builder to access the Scaffold context
                        builder:
                            (ctx) => IconButton(
                              tooltip: AppTooltips.toggleSidebar,
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              icon: const Icon(Icons.menu_rounded),
                            ),
                      ),
                    const Spacer(),
                    Tooltip(
                      message: AppTooltips.premium,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.0.w.clamp(16, 24),
                            vertical: 1.2.h.clamp(10, 14),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const PremiumDialog(),
                          );
                        },
                        icon: const Icon(Icons.stars_rounded),
                        label: Text(AppStrings.premium),
                      ),
                    ),
                    IconButton(
                      tooltip: AppTooltips.theme,
                      onPressed: theme.toggleTheme,
                      icon: Obx(
                        () => Icon(
                          theme.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Base layout — SidebarPanel reaches the very top
              Row(
                children: [
                  if (!isNarrow) const SidebarPanel(),
                  // Chat content padded below the app bar
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: contentTopPadding),
                      child: const ChatArea(
                        // central area
                        maxContentWidth: 1100,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: isNarrow ? Drawer(child: SidebarPanel(inDrawer: true)) : null,
        );
      },
    );
  }
}
