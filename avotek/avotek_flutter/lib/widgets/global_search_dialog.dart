import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/education_provider.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => const GlobalSearchDialog(),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter subjects and topics
    final matchedSubjects = edu.subjects.where((s) {
      if (_query.isEmpty) return true;
      return s.name.toLowerCase().contains(_query) ||
          s.description.toLowerCase().contains(_query);
    }).toList();

    // Examination services
    final examServices = [
      {'name': 'WAEC Result Checker PIN', 'route': '/exams', 'category': 'Exams', 'desc': 'Instant 10-digit PIN for WAEC 2026/past years'},
      {'name': 'NECO Result Token', 'route': '/exams', 'category': 'Exams', 'desc': 'NECO verification token with instant SMS delivery'},
      {'name': 'JAMB UTME / Direct Entry PIN', 'route': '/exams', 'category': 'Exams', 'desc': 'Official profile code PIN for registration'},
      {'name': 'NABTEB Result PIN', 'route': '/exams', 'category': 'Exams', 'desc': 'Technical and business exam result checker'},
    ].where((e) {
      if (_query.isEmpty) return true;
      return e['name']!.toLowerCase().contains(_query) ||
          e['desc']!.toLowerCase().contains(_query);
    }).toList();

    // Connectivity services
    final connectivityServices = [
      {'name': 'Buy Student Airtime', 'route': '/services/airtime', 'category': 'Stay Connected', 'desc': 'MTN, Glo, Airtel, 9mobile instant recharge'},
      {'name': 'Buy Study Data Bundle', 'route': '/services/data', 'category': 'Stay Connected', 'desc': 'SME, Gifting and Night-Study data'},
      {'name': 'Fund Student Wallet', 'route': '/wallet/fund', 'category': 'Wallet', 'desc': 'Dedicated Providus/Wema virtual account'},
      {'name': 'My Study Progress', 'route': '/learn/progress', 'category': 'Learning', 'desc': 'Accuracy, strong subjects, weak subjects'},
      {'name': 'Practice Past Questions', 'route': '/learn/practice', 'category': 'Practice', 'desc': 'WAEC and JAMB past question bank'},
    ].where((c) {
      if (_query.isEmpty) return true;
      return c['name']!.toLowerCase().contains(_query) ||
          c['desc']!.toLowerCase().contains(_query);
    }).toList();

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 580),
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search subjects, topics, exam PINs, practice...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const Divider(height: 1),

            // Search Results List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (_query.isNotEmpty) ...[
                    _buildSectionHeader('LEARNING & SUBJECTS', Icons.menu_book),
                    if (matchedSubjects.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text('No subjects matching query.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                    else
                      ...matchedSubjects.map((s) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: s.color.withValues(alpha: 0.15),
                              child: Icon(s.icon, color: s.color, size: 18),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('${s.topicCount} topics • ${s.questionCount} past questions', style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/learn');
                            },
                          )),
                    const SizedBox(height: 8),
                    _buildSectionHeader('EXAMINATION SERVICES', Icons.school),
                    ...examServices.map((e) => ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE9F5F1),
                            child: Icon(Icons.school, color: Color(0xFF0E7C66), size: 18),
                          ),
                          title: Text(e['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(e['desc']!, style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(e['route']!);
                          },
                        )),
                    const SizedBox(height: 8),
                    _buildSectionHeader('CONNECTIVITY & SERVICES', Icons.wifi),
                    ...connectivityServices.map((c) => ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.bolt, color: AppColors.primaryBlue, size: 18),
                          ),
                          title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(c['desc']!, style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(c['route']!);
                          },
                        )),
                  ] else ...[
                    _buildSectionHeader('QUICK SHORTCUTS', Icons.flash_on),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.quiz_outlined, color: AppColors.primaryBlue, size: 18),
                      ),
                      title: const Text('Practice Past Questions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('WAEC & JAMB multi-choice questions with answers', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/learn/practice');
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE7F6EC),
                        child: Icon(Icons.school_outlined, color: Color(0xFF059669), size: 18),
                      ),
                      title: const Text('Buy Examination PIN (WAEC/NECO/JAMB)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Instant result checker tokens and registration PINs', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/exams');
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFDF4E3),
                        child: Icon(Icons.wifi, color: Color(0xFFB7791F), size: 18),
                      ),
                      title: const Text('Buy Study Data Bundle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Instant data for online lectures, research, and CBT practice', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/services/data');
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF3E8FF),
                        child: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF8B5CF6), size: 18),
                      ),
                      title: const Text('Fund Student Wallet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Instant bank transfer with Providus/Wema dedicated account', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/wallet/fund');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
