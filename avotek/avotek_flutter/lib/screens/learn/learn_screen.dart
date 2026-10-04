import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../models/education_models.dart';
import '../../providers/education_provider.dart';
import '../../widgets/avotek_card.dart';

class LearnScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const LearnScreen({super.key, required this.onToggleTheme});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Sciences',
    'Arts',
    'Commercial',
    'General',
  ];

  void _showTopicsModal(BuildContext context, Subject subject) {
    final edu = context.read<EducationProvider>();
    final topics = edu.getTopicsForSubject(subject.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: subject.color.withValues(alpha: 0.15),
                        child: Icon(subject.icon, color: subject.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${topics.length} Syllabus Topics • WAEC & JAMB Aligned',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Expanded(
                    child: topics.isEmpty
                        ? const Center(
                            child: Text(
                              'Topics and lessons for this subject are loading from the syllabus catalog.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: topics.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final topic = topics[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: topic.isCompleted
                                      ? const Color(0xFFE7F6EC)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  child: Icon(
                                    topic.isCompleted ? Icons.check : Icons.menu_book,
                                    size: 14,
                                    color: topic.isCompleted ? const Color(0xFF059669) : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  topic.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${topic.description} • ${topic.questionCount} past questions',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: subject.color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.push('/learn/practice?subject=${subject.id}');
                                  },
                                  child: const Text('Practice'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final filteredSubjects = edu.subjects.where((s) {
      if (_selectedCategory == 'All') return true;
      return s.category == _selectedCategory;
    }).toList();

    return ResponsiveShell(
      currentRoute: '/learn',
      onToggleTheme: widget.onToggleTheme,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Text(
                'Learn & Practice',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore the Nigerian secondary & tertiary syllabus, study key topic summaries, and practice past examination questions.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Exam Target Card
              AvotekCard(
                padding: const EdgeInsets.all(18),
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                borderColor: const Color(0xFF93C5FD),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0070F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Examination Goals: WAEC 2026 & JAMB CBT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Practice questions with step-by-step explanations curated by experienced national examiners.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => context.push('/learn/practice'),
                      child: const Text('Start Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.primaryBlue,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Subject Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.5 : 1.7,
                ),
                itemCount: filteredSubjects.length,
                itemBuilder: (context, index) {
                  final subject = filteredSubjects[index];

                  return AvotekCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: subject.color.withValues(alpha: 0.15),
                                  child: Icon(subject.icon, color: subject.color, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      subject.category,
                                      style: TextStyle(fontSize: 10, color: subject.color, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: subject.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${subject.questionCount} Qs',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subject.color),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          subject.description,
                          style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showTopicsModal(context, subject),
                                child: const Text('Topics & Notes', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: subject.color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => context.push('/learn/practice?subject=${subject.id}'),
                                child: const Text('Practice Quiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
