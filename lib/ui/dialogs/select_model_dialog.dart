import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/sizer/app_sizer.dart';
import '../../enums/app.enum.dart';
import '../../controllers/chat_controller.dart';

class SelectModelDialog extends StatefulWidget {
  const SelectModelDialog({super.key});

  @override
  State<SelectModelDialog> createState() => _SelectModelDialogState();
}

class _SelectModelDialogState extends State<SelectModelDialog> {
  final _searchCtrl = TextEditingController();
  final Set<ModelCapability> _filters = {};
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleFilter(ModelCapability cap) {
    setState(() {
      if (_filters.contains(cap)) {
        _filters.remove(cap);
      } else {
        _filters.add(cap);
      }
    });
  }

  bool _matchesFilters(ModelMeta meta) {
    if (_filters.isEmpty) return true;
    return _filters.every(meta.caps.contains);
  }

  bool _matchesSearch(ModelMeta meta) {
    if (_query.isEmpty) return true;
    final q = _query;
    return meta.name.toLowerCase().contains(q) ||
        meta.subtitle.toLowerCase().contains(q);
  }

  List<ModelMeta> _modelsForVendor(ModelVendor vendor) {
    final ids = AppModels.byVendor[vendor] ?? const <String>[];
    return ids
        .map(AppModels.meta)
        .where((m) => _matchesFilters(m) && _matchesSearch(m))
        .toList();
  }

  List<Widget> _buildVendorSections(BuildContext context, String currentId) {
    final theme = Theme.of(context);
    final titles = AppModels.vendorTitles;
    final vendors = ModelVendor.values;
    final len = titles.length < vendors.length ? titles.length : vendors.length;
    final widgets = <Widget>[];
    for (var i = 0; i < len; i++) {
      final models = _modelsForVendor(vendors[i]);
      if (models.isEmpty) continue;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: 1.0.h.clamp(8, 16),
            bottom: 0.6.h.clamp(4, 10),
          ),
          child: Text(titles[i], style: theme.textTheme.titleLarge),
        ),
      );
      widgets.addAll(
        models.map(
          (meta) => _ModelTile(meta: meta, isSelected: meta.id == currentId),
        ),
      );
      widgets.add(const Divider(height: 24));
    }
    return widgets;
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.6.h.clamp(10, 22)),
                    child: Text(
                      AppStrings.modelTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                ModelCapability.values.map((cap) {
                                  final selected = _filters.contains(cap);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      avatar: Icon(_capIcon(cap), size: 16),
                                      label: Text(cap.label),
                                      selected: selected,
                                      onSelected: (_) => _toggleFilter(cap),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isNarrow ? 190 : 280,
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchModelsHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                          onChanged:
                              (value) => setState(
                                () => _query = value.trim().toLowerCase(),
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.2.h.clamp(8, 16)),
                  Expanded(
                    child: Obx(() {
                      final sections = _buildVendorSections(
                        context,
                        chat.currentModelId,
                      );
                      if (sections.isEmpty) {
                        return Center(
                          child: Text(
                            AppStrings.noResults,
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }
                      return ListView(children: sections);
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                ? theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )
                : theme.textTheme.titleSmall,
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
                          _capIcon(cap),
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

IconData _capIcon(ModelCapability c) {
  switch (c) {
    case ModelCapability.reasoning:
      return Icons.psychology_alt_outlined;
    case ModelCapability.fileInputs:
      return Icons.attach_file_rounded;
    case ModelCapability.audioInputs:
      return Icons.mic_none_rounded;
    case ModelCapability.textInputs:
      return Icons.chat_bubble_outline_rounded;
  }
}
