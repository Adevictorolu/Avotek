import 'package:flutter/material.dart';
import '../models/education_models.dart';

class EducationProvider extends ChangeNotifier {
  StudentProfileData _profile = const StudentProfileData(
    fullName: 'Chukwuemeka Obi',
    classLevel: 'SS2',
    department: 'Science',
    school: 'Federal Government College, Lagos',
    state: 'Lagos State',
    targetExams: ['WAEC 2026', 'JAMB 2026', 'NECO 2026'],
    enrolledSubjects: ['Mathematics', 'English Language', 'Physics', 'Chemistry', 'Biology'],
    isStudentMode: true,
  );

  List<Subject> _subjects = [];
  Map<String, List<Topic>> _topicsBySubject = {};
  Map<String, List<Lesson>> _lessonsByTopic = {};
  List<Question> _questionBank = [];
  List<PracticeAttempt> _attempts = [];
  List<ExamPinItem> _purchasedPins = [];

  DailyChallenge? _todayChallenge;
  int? _selectedChallengeOption;
  bool _challengeSubmitted = false;
  int _challengeStreak = 5;

  EducationProvider() {
    _initData();
  }

  StudentProfileData get profile => _profile;
  List<Subject> get subjects => _subjects;
  List<Question> get questionBank => _questionBank;
  List<PracticeAttempt> get attempts => _attempts;
  List<ExamPinItem> get purchasedPins => _purchasedPins;
  DailyChallenge? get todayChallenge => _todayChallenge;
  int? get selectedChallengeOption => _selectedChallengeOption;
  bool get challengeSubmitted => _challengeSubmitted;
  int get challengeStreak => _challengeStreak;

  String get studentStatusBadge => '${_profile.classLevel} • ${_profile.department}';

  void toggleStudentMode() {
    _profile = _profile.copyWith(isStudentMode: !_profile.isStudentMode);
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    String? classLevel,
    String? department,
    String? school,
    String? state,
    List<String>? targetExams,
    List<String>? enrolledSubjects,
  }) {
    _profile = _profile.copyWith(
      fullName: fullName,
      classLevel: classLevel,
      department: department,
      school: school,
      state: state,
      targetExams: targetExams,
      enrolledSubjects: enrolledSubjects,
    );
    notifyListeners();
  }

  List<Topic> getTopicsForSubject(String subjectId) {
    return _topicsBySubject[subjectId] ?? [];
  }

  List<Lesson> getLessonsForTopic(String topicId) {
    return _lessonsByTopic[topicId] ?? [];
  }

  List<Question> getQuestionsForPractice({
    required String subjectId,
    String? examType,
    int count = 10,
  }) {
    final list = _questionBank.where((q) {
      if (q.subjectId != subjectId) return false;
      if (examType != null && examType != 'All' && q.examType != examType) return false;
      return true;
    }).toList();

    if (list.length > count) {
      return list.sublist(0, count);
    }
    return list;
  }

  void recordPracticeAttempt({
    required String subjectId,
    required String subjectName,
    required int totalQuestions,
    required int correctCount,
  }) {
    final scorePercent = totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;
    final attempt = PracticeAttempt(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subjectId,
      subjectName: subjectName,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      scorePercentage: scorePercent,
      timestamp: DateTime.now(),
    );

    _attempts.insert(0, attempt);
    notifyListeners();
  }

  void selectChallengeOption(int optionIndex) {
    if (_challengeSubmitted) return;
    _selectedChallengeOption = optionIndex;
    notifyListeners();
  }

  bool submitChallenge() {
    if (_selectedChallengeOption == null || _todayChallenge == null) return false;
    _challengeSubmitted = true;
    final isCorrect = _selectedChallengeOption == _todayChallenge!.correctOptionIndex;
    if (isCorrect) {
      _challengeStreak += 1;
    }
    notifyListeners();
    return isCorrect;
  }

  void addPurchasedPin(ExamPinItem item) {
    _purchasedPins.insert(0, item);
    notifyListeners();
  }

  // Progress metrics
  int get totalQuestionsAttempted {
    return _attempts.fold(0, (sum, a) => sum + a.totalQuestions);
  }

  double get averageScore {
    if (_attempts.isEmpty) return 76.5; // Baseline healthy starter
    final totalScores = _attempts.fold(0.0, (sum, a) => sum + a.scorePercentage);
    return totalScores / _attempts.length;
  }

  Map<String, double> get subjectPerformance {
    final map = <String, List<double>>{};
    for (final a in _attempts) {
      map.putIfAbsent(a.subjectName, () => []).add(a.scorePercentage);
    }

    final result = <String, double>{};
    map.forEach((sub, scores) {
      result[sub] = scores.fold(0.0, (sum, s) => sum + s) / scores.length;
    });

    // Provide helpful defaults if fewer attempts exist
    result.putIfAbsent('Mathematics', () => 72.0);
    result.putIfAbsent('English Language', () => 81.0);
    result.putIfAbsent('Physics', () => 64.0);
    result.putIfAbsent('Chemistry', () => 78.0);
    result.putIfAbsent('Biology', () => 85.0);

    return result;
  }

  void _initData() {
    _subjects = [
      const Subject(
        id: 'maths',
        name: 'Mathematics',
        code: 'MTH',
        category: 'Sciences',
        icon: Icons.calculate_outlined,
        color: Color(0xFF0070F3),
        description: 'Algebra, Trigonometry, Calculus, Statistics and Geometry for WAEC/JAMB.',
        topicCount: 24,
        questionCount: 450,
      ),
      const Subject(
        id: 'english',
        name: 'English Language',
        code: 'ENG',
        category: 'General',
        icon: Icons.menu_book_outlined,
        color: Color(0xFF10B981),
        description: 'Lexis & Structure, Comprehension, Oral Forms, Concord and Essay writing.',
        topicCount: 18,
        questionCount: 380,
      ),
      const Subject(
        id: 'physics',
        name: 'Physics',
        code: 'PHY',
        category: 'Sciences',
        icon: Icons.bolt_outlined,
        color: Color(0xFF8B5CF6),
        description: 'Mechanics, Optics, Electricity, Magnetism and Modern Atomic Physics.',
        topicCount: 22,
        questionCount: 340,
      ),
      const Subject(
        id: 'chemistry',
        name: 'Chemistry',
        code: 'CHM',
        category: 'Sciences',
        icon: Icons.science_outlined,
        color: Color(0xFFF59E0B),
        description: 'Periodic Table, Stoichiometry, Organic Compounds, Acids, Bases and Salts.',
        topicCount: 20,
        questionCount: 320,
      ),
      const Subject(
        id: 'biology',
        name: 'Biology',
        code: 'BIO',
        category: 'Sciences',
        icon: Icons.eco_outlined,
        color: Color(0xFF059669),
        description: 'Ecology, Genetics, Cell Physiology, Respiration and Reproductive systems.',
        topicCount: 26,
        questionCount: 410,
      ),
      const Subject(
        id: 'economics',
        name: 'Economics',
        code: 'ECN',
        category: 'Commercial',
        icon: Icons.trending_up_outlined,
        color: Color(0xFFEC4899),
        description: 'Market Structures, Inflation, National Income, Public Finance and Trade.',
        topicCount: 16,
        questionCount: 290,
      ),
      const Subject(
        id: 'government',
        name: 'Government',
        code: 'GOV',
        category: 'Arts',
        icon: Icons.account_balance_outlined,
        color: Color(0xFF6366F1),
        description: 'Constitutional History, Arms of Government, Political Systems and Foreign Policy.',
        topicCount: 15,
        questionCount: 260,
      ),
      const Subject(
        id: 'literature',
        name: 'Literature in English',
        code: 'LIT',
        category: 'Arts',
        icon: Icons.history_edu_outlined,
        color: Color(0xFFD97706),
        description: 'African & Non-African Prose, Poetry, Drama and Literary Appreciation.',
        topicCount: 14,
        questionCount: 220,
      ),
      const Subject(
        id: 'computer',
        name: 'Computer Studies',
        code: 'CSC',
        category: 'Sciences',
        icon: Icons.laptop_chromebook_outlined,
        color: Color(0xFF0284C7),
        description: 'Data Processing, Algorithms, Hardware Systems, Networking and Cybersecurity.',
        topicCount: 12,
        questionCount: 200,
      ),
    ];

    _topicsBySubject = {
      'maths': [
        const Topic(id: 'm1', subjectId: 'maths', title: 'Algebraic Expressions & Factorisation', description: 'Quadratic equations, polynomials, and simultaneous equations.', lessonCount: 4, questionCount: 45, isCompleted: true),
        const Topic(id: 'm2', subjectId: 'maths', title: 'Trigonometry & Bearing', description: 'Sine/Cosine rules, angles of elevation/depression, and bearings.', lessonCount: 3, questionCount: 38),
        const Topic(id: 'm3', subjectId: 'maths', title: 'Calculus: Differentiation & Integration', description: 'Rates of change, maxima/minima, and area under curves.', lessonCount: 5, questionCount: 50),
        const Topic(id: 'm4', subjectId: 'maths', title: 'Statistics & Probability', description: 'Mean, variance, standard deviation, and permutations/combinations.', lessonCount: 4, questionCount: 42),
      ],
      'physics': [
        const Topic(id: 'p1', subjectId: 'physics', title: 'Motion & Work, Energy, Power', description: 'Linear equations of motion, momentum, and conservation laws.', lessonCount: 4, questionCount: 40, isCompleted: true),
        const Topic(id: 'p2', subjectId: 'physics', title: 'Electric Fields & Current Electricity', description: "Ohm's law, circuit analysis, resistivity, and electromagnetic induction.", lessonCount: 5, questionCount: 48),
        const Topic(id: 'p3', subjectId: 'physics', title: 'Optics & Wave Motion', description: 'Refraction, lenses, sound waves, and resonance.', lessonCount: 3, questionCount: 35),
      ],
      'chemistry': [
        const Topic(id: 'c1', subjectId: 'chemistry', title: 'Atomic Structure & Periodic Trends', description: 'Electronic configuration, ionization energy, and electronegativity.', lessonCount: 3, questionCount: 32, isCompleted: true),
        const Topic(id: 'c2', subjectId: 'chemistry', title: 'Stoichiometry & Mole Concept', description: 'Molar volume, empirical formula, and concentration calculations.', lessonCount: 4, questionCount: 40),
        const Topic(id: 'c3', subjectId: 'chemistry', title: 'Organic Chemistry: Hydrocarbons', description: 'Alkanes, alkenes, alkynes, and functional groups.', lessonCount: 6, questionCount: 55),
      ],
      'english': [
        const Topic(id: 'e1', subjectId: 'english', title: 'Concord & Subject-Verb Agreement', description: 'Rules governing singular/plural subjects and collective nouns.', lessonCount: 3, questionCount: 35, isCompleted: true),
        const Topic(id: 'e2', subjectId: 'english', title: 'Reading Comprehension Strategies', description: 'Inference, identifying figures of speech, and answering precis.', lessonCount: 4, questionCount: 30),
      ],
    };

    _lessonsByTopic = {
      'm1': [
        const Lesson(
          id: 'l_m1_1',
          topicId: 'm1',
          subjectId: 'maths',
          title: 'Quadratic Equations by Factorisation & Formula',
          summary: 'Master standard form ax² + bx + c = 0 and the almighty formula.',
          content: '''
### Quadratic Equations
A quadratic equation is any equation that can be rearranged in standard form as:
**ax² + bx + c = 0** (where a ≠ 0).

#### 1. Quadratic Formula
The roots of any quadratic equation are given by:
`x = (-b ± √(b² - 4ac)) / (2a)`

The term **b² - 4ac** is called the **Discriminant (D)**:
- If **D > 0**: Two distinct real roots.
- If **D = 0**: Exactly one repeated real root.
- If **D < 0**: Complex or imaginary roots.

#### 2. Key Exam Strategy for WAEC/JAMB
Always arrange equations into standard form first before identifying coefficients *a*, *b*, and *c*. Check your answers by substitution!
''',
          readTimeMinutes: 5,
        ),
      ],
    };

    _questionBank = [
      // Mathematics
      const Question(
        id: 'q1',
        subjectId: 'maths',
        topicId: 'm1',
        examType: 'JAMB',
        year: 2024,
        difficulty: 'Medium',
        questionText: 'If 2x + 5 = 15, what is the value of x?',
        options: ['3', '5', '7', '10'],
        correctOptionIndex: 1,
        explanation: 'Subtract 5 from both sides: 2x = 10. Divide by 2: x = 5.',
      ),
      const Question(
        id: 'q2',
        subjectId: 'maths',
        topicId: 'm1',
        examType: 'WAEC',
        year: 2023,
        difficulty: 'Medium',
        questionText: 'Solve for x in the equation: x² - 5x + 6 = 0.',
        options: ['x = 2 or x = 3', 'x = -2 or x = -3', 'x = 1 or x = 6', 'x = -1 or x = 6'],
        correctOptionIndex: 0,
        explanation: 'Factorise: (x - 2)(x - 3) = 0. Therefore x = 2 or x = 3.',
      ),
      const Question(
        id: 'q3',
        subjectId: 'maths',
        topicId: 'm2',
        examType: 'JAMB',
        year: 2024,
        difficulty: 'Hard',
        questionText: 'Find the derivative of f(x) = 3x³ - 5x² + 4x - 7 with respect to x.',
        options: ['9x² - 10x + 4', '6x² - 5x + 4', '9x³ - 10x² + 4', '3x² - 10x'],
        correctOptionIndex: 0,
        explanation: 'Using the power rule d/dx(xⁿ) = n·xⁿ⁻¹: d/dx(3x³) = 9x², d/dx(-5x²) = -10x, d/dx(4x) = 4.',
      ),
      // Physics
      const Question(
        id: 'q4',
        subjectId: 'physics',
        topicId: 'p1',
        examType: 'WAEC',
        year: 2023,
        difficulty: 'Medium',
        questionText: 'A car accelerates uniformly from rest at 2 m/s² for 10 seconds. Calculate the total distance covered.',
        options: ['50 m', '100 m', '200 m', '20 m'],
        correctOptionIndex: 1,
        explanation: 'Using s = ut + ½at² where u = 0: s = 0 + ½(2)(10)² = 100 metres.',
      ),
      const Question(
        id: 'q5',
        subjectId: 'physics',
        topicId: 'p2',
        examType: 'JAMB',
        year: 2024,
        difficulty: 'Easy',
        questionText: 'What is the SI unit of electric potential difference?',
        options: ['Ampere', 'Ohm', 'Volt', 'Coulomb'],
        correctOptionIndex: 2,
        explanation: 'The SI unit of electric potential difference and electromotive force is the Volt (V).',
      ),
      // Chemistry
      const Question(
        id: 'q6',
        subjectId: 'chemistry',
        topicId: 'c1',
        examType: 'JAMB',
        year: 2024,
        difficulty: 'Easy',
        questionText: 'Which element has the electron configuration 1s² 2s² 2p⁶ 3s¹?',
        options: ['Magnesium (Mg)', 'Sodium (Na)', 'Aluminium (Al)', 'Potassium (K)'],
        correctOptionIndex: 1,
        explanation: 'Total electrons = 2 + 2 + 6 + 1 = 11, corresponding to Sodium (Na, atomic number 11).',
      ),
      // English
      const Question(
        id: 'q7',
        subjectId: 'english',
        topicId: 'e1',
        examType: 'WAEC',
        year: 2023,
        difficulty: 'Medium',
        questionText: 'Choose the correct option: Neither the teacher nor the students _____ present at the hall.',
        options: ['was', 'were', 'is', 'has been'],
        correctOptionIndex: 1,
        explanation: 'In correlative conjunctions (neither...nor), the verb agrees with the subject closest to it ("students" is plural, hence "were").',
      ),
      // Biology
      const Question(
        id: 'q8',
        subjectId: 'biology',
        examType: 'JAMB',
        year: 2024,
        difficulty: 'Easy',
        questionText: 'Which organelle is known as the powerhouse of the eukaryotic cell?',
        options: ['Ribosome', 'Mitochondrion', 'Golgi apparatus', 'Nucleolus'],
        correctOptionIndex: 1,
        explanation: 'Mitochondria generate most of the chemical energy needed to power cellular reactions in the form of ATP.',
      ),
    ];

    _todayChallenge = DailyChallenge(
      id: 'dc-today',
      subjectId: 'maths',
      subjectName: 'Mathematics',
      questionText: 'If 2x + 5 = 15, what is the value of x?',
      options: ['5', '10', '15', '20'],
      correctOptionIndex: 0,
      explanation: 'Subtract 5 from both sides: 2x = 10. Divide by 2: x = 5. Well done!',
      date: DateTime.now(),
    );

    _purchasedPins = [
      ExamPinItem(
        id: 'pin-01',
        examType: 'WAEC',
        title: 'WAEC Result Checker PIN (2026)',
        pinCode: 'WAEC-9941-2804-1184',
        serialNumber: 'WR260194821',
        amount: 3900.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
        reference: 'TX-AVO-EXAM-884102',
        status: 'Delivered',
      ),
      ExamPinItem(
        id: 'pin-02',
        examType: 'JAMB',
        title: 'JAMB UTME / DE Registration PIN',
        pinCode: 'JAMB-8472-1094-3829',
        serialNumber: 'JB2026849102',
        amount: 5000.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 7)),
        reference: 'TX-AVO-EXAM-883910',
        status: 'Delivered',
      ),
    ];

    _attempts = [
      PracticeAttempt(
        id: 'att-1',
        subjectId: 'maths',
        subjectName: 'Mathematics',
        totalQuestions: 10,
        correctCount: 8,
        scorePercentage: 80.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      PracticeAttempt(
        id: 'att-2',
        subjectId: 'english',
        subjectName: 'English Language',
        totalQuestions: 10,
        correctCount: 9,
        scorePercentage: 90.0,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PracticeAttempt(
        id: 'att-3',
        subjectId: 'physics',
        subjectName: 'Physics',
        totalQuestions: 10,
        correctCount: 6,
        scorePercentage: 60.0,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
