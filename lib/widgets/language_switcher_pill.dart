import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LanguageSwitcherPill extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final VoidCallback onSwap;

  const LanguageSwitcherPill({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Source language (left half)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                sourceLanguage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Swap button (center)
          GestureDetector(
            onTap: onSwap,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Icon(
                Icons.swap_horiz,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
          ),
          // Target language (right half)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    targetLanguage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
