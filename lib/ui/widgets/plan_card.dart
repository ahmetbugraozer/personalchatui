import 'package:flutter/material.dart';
import 'package:personalchatui/core/sizer/app_sizer.dart';
import 'package:personalchatui/enums/app.enum.dart';

class PlanCard extends StatelessWidget {
  final PricingPlan plan;
  const PlanCard({super.key, required this.plan});

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
      padding: EdgeInsets.all(1.6.h.clamp(14, 20)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isPlus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
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
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.6.h.clamp(4, 10)),
          // Price
          Text(
            plan.price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h.clamp(4, 8)),
          // Blurb - no maxLines limit
          Text(
            plan.blurb,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          SizedBox(height: 1.2.h.clamp(10, 16)),
          // CTA Button
          SizedBox(
            width: double.infinity,
            child:
                isPlus || plan == PricingPlan.pro
                    ? FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 0.9.h.clamp(10, 14),
                        ),
                      ),
                      child: Text(plan.cta),
                    )
                    : OutlinedButton(
                      onPressed: plan == PricingPlan.free ? null : () {},
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 0.9.h.clamp(10, 14),
                        ),
                      ),
                      child: Text(plan.cta),
                    ),
          ),
          SizedBox(height: 1.0.h.clamp(8, 14)),
          // Features - no maxLines limit, full text
          ...plan.features.map(
            (f) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.35.h.clamp(3, 5)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 0.6.w.clamp(6, 8)),
                  Expanded(
                    child: Text(
                      f,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
