import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../models/education_models.dart';
import '../../providers/education_provider.dart';
import '../../widgets/avotek_card.dart';

class PracticeScreen extends StatefulWidget {
  final String? initialSubjectId;
  final VoidCallback onToggleTheme;

  const PracticeScreen({
    super.key,
    this.initialSubjectId,
    required this.onToggleTheme,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // Setup State
  late String _selectedSubjectId;
  String _selectedExamType = 'All';
  int _questionCount = 5;
  bool _quizStarted = false;
  bool _quizCompleted = false;

  // Active Quiz State
  List<Question> _activeQuestions = [];
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // question index -> chosen option index
  bool _showInstantExplanation = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId ?? 'maths';
  }

  void _startQuiz(EducationProvider edu) {
    final questions = edu.getQuestionsForPractice(
      subjectId: _selectedSubjectId,
      examType: _selectedExamType,
      count: _questionCount,
    );

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions found matching your filter criteria. Try selecting another exam type.')),
      );
      return;
    }

    setState(() {
      _activeQuestions = questions;
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _quizStarted = true;
      _quizCompleted = false;
      _showInstantExplanation = false;
    });
  }

  void _finishQuiz(EducationProvider edu) {
    int correct = 0;
    for (int i = 0; i < _activeQuestions.length; i++) {
      if (_userAnswers[i] == _activeQuestions[i].correctOptionIndex) {
        correct++;
      }
    }

    final subject = edu.subjects.firstWhere((s) => s.id == _selectedSubjectId);
    edu.recordPracticeAttempt(
      subjectId: subject.id,
      subjectName: subject.name,
      totalQuestions: _activeQuestions.length,
      correctCount: correct,
    );

    setState(() {
      _quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveShell(
      currentRoute: '/learn',
      onToggleTheme: widget.onToggleTheme,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_quizStarted)
                _buildConfigurationView(edu, isDark)
              else if (_quizCompleted)
                _buildCompletedView(edu, isDark)
              else
                _buildActiveQuizView(edu, isDark),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationView(EducationProvider edu, bool isDark) {
    final currentSubject = edu.subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => edu.subjects.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/learn'),
            ),
            const SizedBox(width: 8),
            const Text(
              'Practice CBT Questions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AvotekCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Your Practice Session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a subject, target exam standard, and the number of practice questions.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Subject Selector
              const Text('Select Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSubjectId,
                    items: edu.subjects.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Row(
                          children: [
                            Icon(s.icon, color: s.color, size: 18),
                            const SizedBox(width: 10),
                            Text(s.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSubjectId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Exam Standard
              const Text('Target Examination Standard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'JAMB', 'WAEC', 'NECO'].map((exam) {
                  final isSelected = _selectedExamType == exam;
                  return ChoiceChip(
                    label: Text(exam),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedExamType = exam);
                    },
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Question Count
              const Text('Number of Questions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [5, 10, 20].map((count) {
                  final isSelected = _questionCount == count;
                  return ChoiceChip(
                    label: Text('$count Questions'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _questionCount = count);
                    },
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Start CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentSubject.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _startQuiz(edu),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Begin ${currentSubject.name} Practice', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveQuizView(EducationProvider edu, bool isDark) {
    final currentQ = _activeQuestions[_currentQuestionIndex];
    final selectedOption = _userAnswers[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _activeQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Progress Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_activeQuestions.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${currentQ.examType} ${currentQ.year} • ${currentQ.difficulty} Difficulty',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () {
                setState(() => _quizStarted = false);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Exit Practice'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 20),

        // Question Card
        AvotekCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentQ.questionText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(currentQ.options.length, (idx) {
                final optionText = currentQ.options[idx];
                final isSelected = selectedOption == idx;
                final isCorrect = idx == currentQ.correctOptionIndex;

                Color bg = isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC);
                Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                Color textCol = isDark ? Colors.white : Colors.black87;

                if (_showInstantExplanation) {
                  if (isCorrect) {
                    bg = const Color(0xFFE7F6EC);
                    border = const Color(0xFF059669);
                    textCol = const Color(0xFF059669);
                  } else if (isSelected && !isCorrect) {
                    bg = const Color(0xFFFEE2E2);
                    border = const Color(0xFFDC2626);
                    textCol = const Color(0xFFDC2626);
                  }
                } else if (isSelected) {
                  bg = AppColors.primaryBlue.withValues(alpha: 0.08);
                  border = AppColors.primaryBlue;
                  textCol = AppColors.primaryBlue;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _userAnswers[_currentQuestionIndex] = idx;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? border : Colors.transparent,
                              border: Border.all(color: isSelected ? border : Colors.grey),
                            ),
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: textCol),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Explanation Box if enabled
              if (_showInstantExplanation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primaryBlue),
                          SizedBox(width: 6),
                          Text('Solution Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(currentQ.explanation, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Navigation Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _currentQuestionIndex > 0
                  ? () {
                      setState(() {
                        _currentQuestionIndex--;
                        _showInstantExplanation = false;
                      });
                    }
                  : null,
              child: const Text('Previous'),
            ),
            Row(
              children: [
                if (selectedOption != null && !_showInstantExplanation)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showInstantExplanation = true);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Show Solution'),
                  ),
                const SizedBox(width: 8),
                if (_currentQuestionIndex < _activeQuestions.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex++;
                        _showInstantExplanation = false;
                      });
                    },
                    child: const Text('Next Question'),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _finishQuiz(edu),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Submit Practice Quiz'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedView(EducationProvider edu, bool isDark) {
    int correct = 0;
    for (int i = 0; i < _activeQuestions.length; i++) {
      if (_userAnswers[i] == _activeQuestions[i].correctOptionIndex) {
        correct++;
      }
    }
    final percent = (_activeQuestions.isNotEmpty ? (correct / _activeQuestions.length) * 100 : 0).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvotekCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE7F6EC),
                ),
                child: const Icon(Icons.emoji_events, size: 48, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Practice Quiz Completed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Your score has been saved to your academic progress.',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              const SizedBox(height: 20),

              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: percent >= 70 ? const Color(0xFF059669) : (percent >= 50 ? const Color(0xFFB7791F) : const Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$correct out of ${_activeQuestions.length} Questions Correct',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _quizStarted = false;
                        _quizCompleted = false;
                      });
                    },
                    child: const Text('Practice Again'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.go('/learn/progress'),
                    child: const Text('View Full Progress'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
