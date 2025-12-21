import 'package:flutter/material.dart';
import 'package:personalchatui/ui/widgets/input/dashed_border_painter.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../enums/app.enum.dart';

class ContentDropzone extends StatelessWidget {
  final bool uploading;

  const ContentDropzone({super.key, required this.uploading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black87;

    return IgnorePointer(
      ignoring: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, // opaque background
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: borderColor,
            strokeWidth: 1.5,
            dash: 8,
            gap: 6,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Wrap in a non-interactive scroll view to avoid overflow in very small heights
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.0.h.clamp(6, 12)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppTooltips.attachFile,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.0.h.clamp(6, 14)),
                        Text(
                          AppStrings.supportedExts,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 0.6.h.clamp(4, 10)),
                        Text(
                          AppStrings.maxSizeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.0.h.clamp(8, 16)),
                        if (uploading)
                          SizedBox(
                            width: 220,
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: theme.dividerColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
