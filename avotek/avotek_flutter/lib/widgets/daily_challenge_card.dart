import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/education_provider.dart';
import 'avotek_card.dart';
import 'status_badge.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final challenge = edu.todayChallenge;

    if (challenge == null) {
      return const SizedBox.shrink();
    }

    final isSubmitted = edu.challengeSubmitted;
    final selectedIdx = edu.selectedChallengeOption;
    final isCorrect = isSubmitted && selectedIdx == challenge.correctOptionIndex;

    return AvotekCard(
      padding: const EdgeInsets.all(22),
      borderColor: isSubmitted
          ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0070F3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on, color: Color(0xFF0070F3), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Today's Challenge",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.academic(challenge.subjectName),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Test your daily academic recall & build streaks',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 13)),
                    Text(
                      '${edu.challengeStreak} Days',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Prompt
          Text(
            challenge.questionText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Options Grid
          ...List.generate(challenge.options.length, (idx) {
            final optionText = challenge.options[idx];
            final isSelected = selectedIdx == idx;
            final isThisOptionCorrect = idx == challenge.correctOptionIndex;

            Color optionBg = isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC);
            Color optionBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
            Color textColor = isDark ? Colors.white : Colors.black87;

            if (isSubmitted) {
              if (isThisOptionCorrect) {
                optionBg = const Color(0xFFE7F6EC);
                optionBorder = const Color(0xFF059669);
                textColor = const Color(0xFF059669);
              } else if (isSelected && !isThisOptionCorrect) {
                optionBg = const Color(0xFFFEE2E2);
                optionBorder = const Color(0xFFDC2626);
                textColor = const Color(0xFFDC2626);
              }
            } else if (isSelected) {
              optionBg = const Color(0xFF0070F3).withValues(alpha: 0.08);
              optionBorder = const Color(0xFF0070F3);
              textColor = const Color(0xFF0070F3);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitted ? null : () => edu.selectChallengeOption(idx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: optionBorder, width: isSelected || (isSubmitted && isThisOptionCorrect) ? 1.5 : 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected || (isSubmitted && isThisOptionCorrect)
                                ? optionBorder
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected || (isSubmitted && isThisOptionCorrect)
                                  ? optionBorder
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected || (isSubmitted && isThisOptionCorrect)
                                  ? Colors.white
                                  : (isDark ? Colors.grey : Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (isSubmitted && isThisOptionCorrect)
                          const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18)
                        else if (isSubmitted && isSelected && !isThisOptionCorrect)
                          const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Submit Button or Explanation
          if (!isSubmitted) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: selectedIdx != null ? () => edu.submitChallenge() : null,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit Today’s Answer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFFE7F6EC) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect ? const Color(0xFF059669) : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.lightbulb_outline,
                        color: isCorrect ? const Color(0xFF059669) : AppColors.primaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCorrect ? 'Correct! Streak +1' : 'Explanation & Solution:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? const Color(0xFF059669) : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    challenge.explanation,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isCorrect ? const Color(0xFF065F46) : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
