import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/education_provider.dart';
import '../../widgets/avotek_card.dart';

class ProgressScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const ProgressScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final performance = edu.subjectPerformance;
    final avgScore = edu.averageScore.round();
    final totalQs = edu.totalQuestionsAttempted > 0 ? edu.totalQuestionsAttempted : 42;

    return ResponsiveShell(
      currentRoute: '/learn',
      onToggleTheme: onToggleTheme,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Academic Progress',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Performance analytics, subject mastery, and examination readiness.',
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push('/learn/practice'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4 Academic Metric Cards (Adapted from Meridian metrics)
              _buildMetricsGrid(isDesktop, isDark, totalQs, avgScore, edu.challengeStreak),
              const SizedBox(height: 28),

              // Subject Mastery Breakdown
              AvotekCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subject Mastery & Proficiency',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Target: 75%+ Mastery',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ...performance.entries.map((entry) {
                      final subject = entry.key;
                      final score = entry.value;
                      final scoreInt = score.round();

                      Color barColor = const Color(0xFF059669);
                      if (scoreInt < 65) {
                        barColor = const Color(0xFFDC2626);
                      } else if (scoreInt < 75) {
                        barColor = const Color(0xFFF59E0B);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subject,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '$scoreInt%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: barColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: score / 100.0,
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommendations: Strong vs Weak Areas
              _buildStrengthsAndFocusGrid(isDesktop, isDark),
              const SizedBox(height: 28),

              // Recent Practice History
              _buildRecentAttemptsList(context, edu, isDark),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    bool isDesktop,
    bool isDark,
    int totalQs,
    int avgScore,
    int streak,
  ) {
    final metrics = [
      {
        'label': 'Questions Attempted',
        'value': '$totalQs',
        'sub': '+15 this week',
        'icon': Icons.quiz_outlined,
        'color': const Color(0xFF0070F3),
      },
      {
        'label': 'Average Accuracy',
        'value': '$avgScore%',
        'sub': 'Across all subjects',
        'icon': Icons.insights_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'label': 'Daily Challenge Streak',
        'value': '$streak Days',
        'sub': 'Keep it going!',
        'icon': Icons.local_fire_department_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Syllabus Topics Cleared',
        'value': '8 / 48',
        'sub': '16.6% Completed',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    final columns = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.7 : 1.35,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        final col = m['color'] as Color;

        return AvotekCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m['label'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  Icon(m['icon'] as IconData, size: 18, color: col),
                ],
              ),
              Text(
                m['value'] as String,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              Text(
                m['sub'] as String,
                style: TextStyle(fontSize: 11, color: col, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrengthsAndFocusGrid(bool isDesktop, bool isDark) {
    return Row(
      children: [
        // Strong Subjects
        Expanded(
          child: AvotekCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF059669), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Strongest Subjects',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '• Biology (85%)\n• English Language (81%)',
                  style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF065F46)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Focus Areas
        Expanded(
          child: AvotekCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Needs Revision Focus',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '• Physics (64% — Motion & Optics)\n• Mathematics (72% — Calculus)',
                  style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAttemptsList(BuildContext context, EducationProvider edu, bool isDark) {
    final attempts = edu.attempts;

    return AvotekCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history_edu_outlined, size: 20, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Recent Practice Quiz Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (attempts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No practice attempts yet. Begin your first quiz today!'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attempts.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final a = attempts[i];
                final scoreInt = a.scorePercentage.round();
                final dateFormat = DateFormat('MMM d, h:mm a');

                Color scoreColor = const Color(0xFF059669);
                if (scoreInt < 65) {
                  scoreColor = const Color(0xFFDC2626);
                } else if (scoreInt < 75) {
                  scoreColor = const Color(0xFFF59E0B);
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scoreColor.withValues(alpha: 0.12),
                    child: Text(
                      '$scoreInt%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                  ),
                  title: Text(a.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    '${a.correctCount} of ${a.totalQuestions} questions correct • ${dateFormat.format(a.timestamp)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => context.push('/learn/practice?subject=${a.subjectId}'),
                );
              },
            ),
        ],
      ),
    );
  }
}
