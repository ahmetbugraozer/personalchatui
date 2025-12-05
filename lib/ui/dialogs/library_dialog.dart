import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/sizer/app_sizer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

import '../../controllers/chat_controller.dart';
import '../../enums/app.enum.dart';
import '../widgets/gallery_grid.dart';
import 'elements/dialog_scaffold.dart';

class LibraryDialog extends StatefulWidget {
  const LibraryDialog({super.key});

  @override
  State<LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<LibraryDialog> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = Get.find<ChatController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final maxWidth =
            isNarrow ? constraints.maxWidth : 90.w.clamp(720, 1200) as double;
        final maxHeight =
            isNarrow
                ? 80.h.clamp(420, 860) as double
                : 74.h.clamp(520, 820) as double;

        return Obx(() {
          final items = chat.galleryImages();

          if (items.isEmpty) {
            return DialogScaffold(
              title: AppStrings.images,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              content: Center(
                child: Text(
                  AppStrings.noImages,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            );
          }

          final bool inPhoto = _selected != null;
          final int effectiveIndex =
              inPhoto ? _selected!.clamp(0, items.length - 1) : 0;

          if (inPhoto) {
            // Photo view uses custom layout
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: 4.w.clamp(12, 32),
                vertical: 3.h.clamp(16, 36),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(2.h.clamp(12, 24)),
                  child: _PhotoView(
                    items: items,
                    index: effectiveIndex,
                    onSelect: (i) => setState(() => _selected = i),
                    onClose: () => setState(() => _selected = null),
                  ),
                ),
              ),
            );
          }

          return DialogScaffold(
            title: AppStrings.images,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            content: GalleryGrid(
              items: items,
              onTap: (i) => setState(() => _selected = i),
            ),
          );
        });
      },
    );
  }
}

// PhotoView
class _PhotoView extends StatelessWidget {
  final List<ImageRef> items;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const _PhotoView({
    required this.items,
    required this.index,
    required this.onSelect,
    required this.onClose,
  });

  void _openInChat(BuildContext context, ImageRef it) {
    final chat = Get.find<ChatController>();
    chat.selectSession(it.sessionIndex);
    Navigator.of(context).pop('openChat');
  }

  void _download(BuildContext context, ImageRef it) {
    final name = it.attachment.name;
    // We don't have real bytes; generate a simple text payload so download works on web.
    if (kIsWeb) {
      final content = 'Downloaded placeholder for $name';
      final bytes = html.Blob([content]);
      final url = html.Url.createObjectUrlFromBlob(bytes);
      final anchor = html.AnchorElement(href: url)..download = name;
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For non-web, show a simple notification (no real file path available)
      Get.snackbar(
        AppStrings.library,
        '${AppTooltips.downloadImage}: $name',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = items[index];
    final chat = Get.find<ChatController>();
    final String sessionTitle = chat.titleFor(it.sessionIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                sessionTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: AppTooltips.downloadImage,
              icon: const Icon(Icons.download_rounded),
              onPressed: () => _download(context, it),
            ),
            IconButton(
              tooltip: AppTooltips.openInChat,
              icon: const Icon(Icons.chat_bubble_rounded),
              onPressed: () => _openInChat(context, it),
            ),
            IconButton(
              tooltip: AppStrings.close,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            ),
          ],
        ),
        SizedBox(height: 1.0.h.clamp(8, 14)),
        // Large preview
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _LargePreview(attachmentName: it.attachment.name),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.2.h.clamp(8, 16)),
        // Thumbnails
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final sel = i == index;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          sel ? theme.colorScheme.primary : theme.dividerColor,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _ThumbTile(attachmentName: items[i].attachment.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Placeholder thumbnail tile (works without real image bytes)
class _ThumbTile extends StatelessWidget {
  final String attachmentName;
  const _ThumbTile({required this.attachmentName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient sheen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.image_rounded,
              size: 30,
              color: theme.iconTheme.color?.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              attachmentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// Large placeholder preview
class _LargePreview extends StatelessWidget {
  final String attachmentName;
  const _LargePreview({required this.attachmentName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.image_rounded,
              size: 96,
              color: theme.iconTheme.color?.withValues(alpha: 0.85),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              attachmentName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
