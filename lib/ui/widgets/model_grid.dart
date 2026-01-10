import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModelGrid extends StatelessWidget {
  final List<String> logoUrls;
  final double size; // overall square size
  final double radius; // corner radius for cells when grid is shown
  final double? gap; // optional gap override

  const ModelGrid({
    super.key,
    required this.logoUrls,
    this.size = 24,
    this.radius = 4,
    this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Unique + capped (first N)
    final seen = <String>{};
    final uniq = <String>[];
    for (final u in logoUrls) {
      if (seen.add(u)) uniq.add(u);
      if (uniq.length >= 4) break;
    }
    if (uniq.isEmpty) return const SizedBox.shrink();

    // Single logo (keep original rounded avatar look)
    if (uniq.length == 1) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
        ),
        padding: EdgeInsets.all(size * 0.1),
        child: SvgPicture.asset(
          uniq.first,
          fit: BoxFit.contain,
          placeholderBuilder:
              (_) => Icon(
                Icons.auto_awesome,
                size: size * 0.6,
                color: theme.iconTheme.color,
              ),
        ),
      );
    }

    // 2x2 compact grid with better spacing
    final actualGap = gap ?? (size > 24 ? 2.0 : 1.5);
    final cell = (size - actualGap) / 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 2),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      padding: EdgeInsets.all(actualGap / 2),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: actualGap,
        crossAxisSpacing: actualGap,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children:
            uniq.take(4).map((p) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Container(
                  width: cell,
                  height: cell,
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: EdgeInsets.all(cell * 0.08),
                    child: SvgPicture.asset(
                      p,
                      fit: BoxFit.contain,
                      placeholderBuilder:
                          (_) => Container(
                            color: Theme.of(context).dividerColor,
                            alignment: Alignment.center,
                            child: Icon(Icons.auto_awesome, size: cell * 0.5),
                          ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
