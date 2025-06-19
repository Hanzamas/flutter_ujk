import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  // ✅ Add backward compatibility parameters
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    // ✅ New parameters for backward compatibility
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Use actionText/onAction if provided, otherwise use buttonText/onButtonPressed
    final displayButtonText = actionText ?? buttonText;
    final displayOnPressed = onAction ?? onButtonPressed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (displayButtonText != null && displayOnPressed != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: displayButtonText,
                onPressed: displayOnPressed,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}