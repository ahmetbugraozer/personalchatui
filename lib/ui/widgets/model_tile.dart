import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:personalchatui/core/sizer/app_sizer.dart';
import 'package:personalchatui/enums/app.enum.dart';
import 'package:personalchatui/ui/dialogs/select_model_dialog.dart';

class ModelTile extends StatelessWidget {
  final ModelMeta meta;
  final bool isSelected;
  const ModelTile({super.key, required this.meta, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caps = meta.caps;
    return ListTile(
      dense: false,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SvgPicture.asset(
          meta.logoUrl,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Icon(Icons.auto_awesome, size: 24),
        ),
      ),
      title: Text(
        meta.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            isSelected
                ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )
                : theme.textTheme.titleMedium,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 0.3.h.clamp(2, 6)),
        child: Text(
          meta.subtitle,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              caps
                  .map(
                    (cap) => Tooltip(
                      message: cap.label,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          capIcon(cap),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
      onTap: () => Navigator.of(context).pop(meta.id),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.06),
    );
  }
}
