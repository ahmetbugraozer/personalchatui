import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModelGrid extends StatelessWidget {
  final List<String> logoUrls;
  final double size; // overall square size
  final double radius; // corner radius for cells when grid is shown

  const ModelGrid({
    super.key,
    required this.logoUrls,
    this.size = 18,
    this.radius = 3,
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            uniq.first,
            fit: BoxFit.contain,
            placeholderBuilder:
                (_) => Icon(
                  Icons.auto_awesome,
                  size: size - 2,
                  color: theme.iconTheme.color,
                ),
          ),
        ),
      );
    }

    // 2x2 compact grid
    final gap = 1.0;
    final cell = (size - gap) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children:
            uniq.take(4).map((p) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox(
                  width: cell,
                  height: cell,
                  child: SvgPicture.asset(
                    p,
                    fit: BoxFit.cover,
                    placeholderBuilder:
                        (_) => Container(
                          color: Theme.of(context).dividerColor,
                          alignment: Alignment.center,
                          child: Icon(Icons.auto_awesome, size: cell * 0.6),
                        ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
