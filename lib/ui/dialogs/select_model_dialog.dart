import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import '../../enums/app.enum.dart';
import '../../controllers/chat_controller.dart';

class SelectModelDialog extends StatelessWidget {
  const SelectModelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = Get.find<ChatController>();
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 4.w.clamp(12, 32),
        vertical: 3.h.clamp(16, 36),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final maxWidth =
              isNarrow ? constraints.maxWidth : 86.w.clamp(680, 980) as double;
          final maxHeight =
              isNarrow
                  ? 78.h.clamp(420, 820) as double
                  : 70.h.clamp(520, 760) as double;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(2.h.clamp(12, 24)),
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.6.h.clamp(10, 22)),
                    child: Text(
                      'Select a model',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Obx(() {
                    final currentId = chat.currentModelId;
                    final titles = AppModels.vendorTitles;
                    final vendors = ModelVendor.values;
                    final len =
                        titles.length < vendors.length
                            ? titles.length
                            : vendors.length;
                    final widgets = <Widget>[];
                    for (var i = 0; i < len; i++) {
                      widgets.addAll(
                        _buildVendorSection(
                          context,
                          titles[i],
                          vendors[i],
                          currentId,
                        ),
                      );
                    }
                    return Column(children: widgets);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildVendorSection(
    BuildContext context,
    String title,
    ModelVendor vendor,
    String currentModelId,
  ) {
    final theme = Theme.of(context);
    final ids = AppModels.byVendor[vendor] ?? const <String>[];
    if (ids.isEmpty) return const [];
    return [
      Padding(
        padding: EdgeInsets.only(
          top: 1.0.h.clamp(8, 16),
          bottom: 0.6.h.clamp(4, 10),
        ),
        child: Text(title, style: theme.textTheme.titleLarge),
      ),
      ...ids.map((id) {
        final m = AppModels.meta(id);
        final selected = m.id == currentModelId;
        return _ModelTile(meta: m, isSelected: selected);
      }),
      const Divider(height: 24),
    ];
  }
}

class _ModelTile extends StatelessWidget {
  final ModelMeta meta;
  final bool isSelected;
  const _ModelTile({required this.meta, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caps = meta.caps;

    IconData capIcon(ModelCapability c) {
      switch (c) {
        case ModelCapability.reasoning:
          return Icons.psychology_alt_outlined;
        case ModelCapability.fileInputs:
          return Icons.attach_file_rounded;
        case ModelCapability.audioInputs:
          return Icons.mic_none_rounded;
      }
    }

    return ListTile(
      dense: false,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.asset(
          meta.logoUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome),
        ),
      ),
      title: Text(
        meta.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            isSelected
                ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )
                : theme.textTheme.titleSmall,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 0.3.h.clamp(2, 6)),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              meta.subtitle,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ...caps.map(
              (c) => Icon(
                capIcon(c),
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
              : const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).pop(meta.id),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.06),
    );
  }
}
