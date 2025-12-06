import 'package:flutter/material.dart';
import 'package:personalchatui/ui/widgets/plan_card.dart';
import '../../core/sizer/app_sizer.dart';
import '../../enums/app.enum.dart';
import 'elements/dialog_scaffold.dart';

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow: < 900px (vertical layout)
        // Wide: >= 900px (horizontal layout with 4 cards in a row)
        final isNarrow = constraints.maxWidth < 900;

        final maxWidth =
            isNarrow
                ? (constraints.maxWidth * 0.95).clamp(320.0, 480.0)
                : 92.w.clamp(800, 1100) as double;

        if (isNarrow) {
          // Vertical layout - use DialogScaffold with Expanded content
          final maxHeight = 80.h.clamp(500, 900) as double;
          return DialogScaffold(
            title: AppStrings.pricingTitle,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            content: _buildVerticalLayout(context),
          );
        }

        // Horizontal layout - use DialogScaffold with IntrinsicHeight
        return DialogScaffold(
          title: AppStrings.pricingTitle,
          maxWidth: maxWidth,
          useIntrinsicHeight: true,
          content: _buildHorizontalLayout(context),
        );
      },
    );
  }

  // Vertical layout for narrow screens - scrollable column
  Widget _buildVerticalLayout(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 0.8.h.clamp(6, 12)),
      itemCount: PricingPlan.values.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.2.h.clamp(10, 16)),
      itemBuilder: (context, index) {
        return PlanCard(plan: PricingPlan.values[index]);
      },
    );
  }

  // Horizontal layout for wide screens - 4 cards in a row with equal height
  Widget _buildHorizontalLayout(BuildContext context) {
    final plans = PricingPlan.values;
    final cardSpacing = 1.2.w.clamp(8, 14) as double;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < plans.length; i++) ...[
          Expanded(child: PlanCard(plan: plans[i])),
          if (i < plans.length - 1) SizedBox(width: cardSpacing),
        ],
      ],
    );
  }
}
