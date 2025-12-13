import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:personalchatui/ui/widgets/model_tile.dart';
import '../../core/sizer/app_sizer.dart';
import '../../enums/app.enum.dart';
import '../../controllers/chat_controller.dart';
import 'elements/dialog_scaffold.dart';

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
          (meta) => ModelTile(meta: meta, isSelected: meta.id == currentId),
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

    return DialogScaffold(
      title: AppStrings.modelTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Responsive filter chips and search field
          LayoutBuilder(
            builder: (context, constraints) {
              const breakpoint = 500.0;
              final isNarrow = constraints.maxWidth < breakpoint;

              if (isNarrow) {
                // Vertical layout: search bar on top, filter chips below
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search field
                    SizedBox(
                      height: dialogInputHeight(context),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchModelsHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: dialogInputPadding(context),
                          isDense: true,
                        ),
                        onChanged:
                            (value) => setState(
                              () => _query = value.trim().toLowerCase(),
                            ),
                      ),
                    ),
                    SizedBox(height: 0.8.h.clamp(6, 12)),
                    // Filter chips wrapped
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ModelCapability.values.map((cap) {
                            final selected = _filters.contains(cap);
                            return FilterChip(
                              avatar: Icon(capIcon(cap), size: 16),
                              label: Text(cap.label),
                              selected: selected,
                              onSelected: (_) => _toggleFilter(cap),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                    ),
                  ],
                );
              } else {
                // Horizontal layout: chips and search bar in same row
                return SizedBox(
                  height: dialogInputHeight(context),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filter chips
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
                                      avatar: Icon(capIcon(cap), size: 16),
                                      label: Text(cap.label),
                                      selected: selected,
                                      onSelected: (_) => _toggleFilter(cap),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search field
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchModelsHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            contentPadding: dialogInputPadding(context),
                            isDense: true,
                          ),
                          onChanged:
                              (value) => setState(
                                () => _query = value.trim().toLowerCase(),
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          SizedBox(height: 1.2.h.clamp(8, 16)),
          // Model list
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

              // IMPORTANT: Constrain ListTile/Ink painting to the scroll area only.
              return Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: ClipRect(
                  child: ListView(padding: EdgeInsets.zero, children: sections),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

IconData capIcon(ModelCapability c) {
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
