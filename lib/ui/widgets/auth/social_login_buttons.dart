import 'package:flutter/material.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../enums/app.enum.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonSize = 5.2.h.clamp(44.0, 56.0);
    final iconSize = 5.2.h.clamp(20.0, 26.0);
    final spacing = 5.2.w.clamp(10.0, 16.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          tooltip: AppTooltips.authLoginWithGoogle,
          icon: Icons.g_mobiledata_rounded,
          logoUrl: logoUrls['google']!,
          size: buttonSize,
          iconSize: iconSize,
          onTap: () {
            // TODO: Google login
          },
        ),
        SizedBox(width: spacing),
        _SocialButton(
          tooltip: AppTooltips.authLoginWithApple,
          icon: Icons.apple_rounded,
          logoUrl: logoUrls['apple']!,
          size: buttonSize,
          iconSize: iconSize,
          onTap: () {
            // TODO: Apple login
          },
        ),
        SizedBox(width: spacing),
        _SocialButton(
          tooltip: AppTooltips.authLoginWithFacebook,
          icon: Icons.facebook_rounded,
          logoUrl: logoUrls['facebook']!,
          size: buttonSize,
          iconSize: iconSize,
          onTap: () {
            // TODO: Facebook login
          },
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String logoUrl;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _SocialButton({
    required this.tooltip,
    required this.icon,
    required this.logoUrl,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Image.network(
                logoUrl,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => Icon(
                      icon,
                      size: iconSize,
                      color: theme.iconTheme.color,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
