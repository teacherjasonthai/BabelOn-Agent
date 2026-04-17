import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LanguageCard extends StatelessWidget {
  final String language;
  final String text;
  final VoidCallback? onClear;
  final List<Widget> actionButtons;
  final bool showSpeaker;

  const LanguageCard({
    super.key,
    required this.language,
    required this.text,
    this.onClear,
    this.actionButtons = const [],
    this.showSpeaker = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with language and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (showSpeaker)
                      const Icon(
                        Icons.volume_up,
                        color: AppColors.primaryRed,
                        size: 18,
                      ),
                    if (showSpeaker) const SizedBox(width: 8),
                    Text(
                      language,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ...actionButtons,
                    if (onClear != null)
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Text content
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text.isEmpty ? 'No text yet' : text,
                  style: TextStyle(
                    color: text.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: text.isEmpty ? FontWeight.normal : FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
