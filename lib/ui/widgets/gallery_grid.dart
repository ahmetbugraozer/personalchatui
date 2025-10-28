import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';

class GalleryGrid extends StatelessWidget {
  final List<ImageRef> items;
  final ValueChanged<int> onTap;

  const GalleryGrid({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        int cross = 2;
        if (w >= 1000) {
          cross = 5;
        } else if (w >= 820) {
          cross = 4;
        } else if (w >= 640) {
          cross = 3;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            return InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(12),
              child: _ThumbTile(attachmentName: it.attachment.name),
            );
          },
        );
      },
    );
  }
}

// Local thumbnail tile (same look-and-feel as dialog)
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
