import 'package:flutter/material.dart';
import '../../core/sizer/app_sizer.dart';

import '../../enums/app.enum.dart';

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          final cardWidth = isNarrow ? maxWidth - 4.w : (maxWidth - 3.6.w) / 2;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(2.h.clamp(12, 24)),
              child: Column(
                children: [
                  Text(
                    AppStrings.pricingTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 1.6.h.clamp(10, 24)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 1.2.w.clamp(8, 20),
                        runSpacing: 1.2.h.clamp(8, 20),
                        children:
                            PricingPlan.values
                                .map(
                                  (p) => SizedBox(
                                    width: cardWidth,
                                    child: _PlanCard(plan: p),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.0.h.clamp(6, 14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppStrings.close),
                      ),
                      SizedBox(width: 1.2.w.clamp(8, 16)),
                      FilledButton(
                        onPressed: () {},
                        child: Text(AppStrings.continueAction),
                      ),
                    ],
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

class _PlanCard extends StatelessWidget {
  final PricingPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlus = plan.isPopular;

    final Color cardBg =
        isPlus
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.cardColor;
    final Color border =
        isPlus
            ? theme.colorScheme.primary.withValues(alpha: 0.35)
            : theme.dividerColor;
    final Color titleColor =
        isPlus
            ? theme.colorScheme.primary
            : theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    final Color textColor =
        isPlus
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.all(1.6.h.clamp(12, 20)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and "Popüler" tag for Plus
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                  ),
                ),
              ),
              if (isPlus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    AppStrings.planPopularTag.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.6.h.clamp(6, 12)),
          Text(plan.price, style: theme.textTheme.headlineSmall?.copyWith()),
          SizedBox(height: 0.6.h.clamp(6, 12)),
          Text(
            plan.blurb,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 1.2.h.clamp(8, 16)),
          SizedBox(
            width: double.infinity,
            child:
                isPlus || plan == PricingPlan.pro
                    ? FilledButton(onPressed: () {}, child: Text(plan.cta))
                    : OutlinedButton(
                      onPressed: plan == PricingPlan.free ? null : () {},
                      child: Text(plan.cta),
                    ),
          ),
          SizedBox(height: 1.0.h.clamp(6, 14)),
          ...plan.features.map(
            (f) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.3.h.clamp(2, 6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 1.w.clamp(6, 10)),
                  Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
