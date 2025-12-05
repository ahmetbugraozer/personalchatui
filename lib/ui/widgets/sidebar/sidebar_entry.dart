import 'package:flutter/material.dart';

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

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 40,
                alignment: Alignment.center,
                child: Icon(displayIcon, size: 22),
              ),
              if (open)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
