import 'package:flutter/material.dart';
import '../../../core/sizer/app_sizer.dart';

class SidebarEntry extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool open;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SidebarEntry({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.open,
    this.isSelected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayIcon = isSelected ? (selectedIcon ?? icon) : icon;

    // Responsive sizing (clamped to keep sane on very small/large screens)
    final radius = 1.2.cw(context).clamp(8.0, 12.0);
    final hPad = 1.0.cw(context).clamp(8.0, 12.0);
    final vPad = 0.6.ch(context).clamp(4.0, 8.0);

    final iconBoxW = 5.2.cw(context).clamp(40.0, 52.0);
    final iconBoxH = 4.8.ch(context).clamp(36.0, 44.0);
    final iconSize = 2.2.csp(context).clamp(18.0, 24.0);

    final labelVPad = 1.2.ch(context).clamp(8.0, 12.0);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            children: [
              Container(
                width: iconBoxW,
                height: iconBoxH,
                alignment: Alignment.center,
                child: Icon(displayIcon, size: iconSize),
              ),
              if (open)
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: labelVPad),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (trailing != null)
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: trailing!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
