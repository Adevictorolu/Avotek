import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/education_provider.dart';
import '../../widgets/avotek_card.dart';
import '../../widgets/status_badge.dart';

class StudentProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const StudentProfileScreen({super.key, required this.onToggleTheme});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  void _openEditProfileDialog(EducationProvider edu) {
    final nameCtrl = TextEditingController(text: edu.profile.fullName);
    final schoolCtrl = TextEditingController(text: edu.profile.school);
    String selectedClass = edu.profile.classLevel;
    String selectedDept = edu.profile.department;
    String selectedState = edu.profile.state;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Student Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: schoolCtrl,
                  decoration: const InputDecoration(labelText: 'School / Institution'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class / Academic Level'),
                  items: ['JSS3', 'SS1', 'SS2', 'SS3', 'JAMB Candidate', 'Undergraduate'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedClass = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept,
                  decoration: const InputDecoration(labelText: 'Department / Track'),
                  items: ['Science', 'Arts', 'Commercial', 'General'].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDept = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                edu.updateProfile(
                  fullName: nameCtrl.text.trim(),
                  school: schoolCtrl.text.trim(),
                  classLevel: selectedClass,
                  department: selectedDept,
                  state: selectedState,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student profile updated successfully!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set 4-Digit Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your PIN authorizes wallet debits and examination purchases.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New 4-Digit PIN',
                hintText: '••••',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction security PIN updated successfully.')),
              );
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = edu.profile;
    final userName = auth.user?.name ?? profile.fullName;
    final userEmail = auth.user?.email ?? 'student@avotek.africa';
    final userPhone = auth.user?.phone ?? '0803 123 4567';

    final initials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'CO';

    return ResponsiveShell(
      currentRoute: '/profile',
      onToggleTheme: widget.onToggleTheme,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Student Profile & Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your academic details, exam targets, transaction security, and experience mode.',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              const SizedBox(height: 24),

              // Profile Card
              AvotekCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  StatusBadge.academic(edu.studentStatusBadge),
                                  const SizedBox(width: 8),
                                  Text(
                                    profile.state,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile.school,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openEditProfileDialog(edu),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Registered Subjects
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text('Enrolled Subjects:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: profile.enrolledSubjects.map((sub) {
                              return Chip(
                                label: Text(sub, style: const TextStyle(fontSize: 11)),
                                backgroundColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Target Exams
                    Row(
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text('Target Exams:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                        Wrap(
                          spacing: 6,
                          children: profile.targetExams.map((exam) {
                            return StatusBadge.success(exam);
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Experience Mode Toggle (Student Mode vs General User Mode)
              AvotekCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              profile.isStudentMode ? Icons.school : Icons.person_outline,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.isStudentMode ? 'Student Mode (Active)' : 'General User Mode (Active)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.isStudentMode
                              ? 'Tailored for secondary and tertiary students with education-first navigation.'
                              : 'Simplified for parents, agents, and professionals who just need VTU & Exam PINs.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Switch(
                      value: profile.isStudentMode,
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (val) => edu.toggleStudentMode(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security & Credentials
              const Text('Security & Security Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AvotekCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.pin, color: AppColors.primaryBlue),
                      title: const Text('Transaction Authorization PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('4-digit PIN required to authorise wallet payments and exam tokens', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePinDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_iphone, color: Color(0xFF059669)),
                      title: const Text('Phone Number Verification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('$userPhone • Verified via SMS OTP', style: const TextStyle(fontSize: 12)),
                      trailing: const StatusBadge(label: 'Verified', icon: Icons.check),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: Color(0xFF8B5CF6)),
                      title: const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(userEmail, style: const TextStyle(fontSize: 12)),
                      trailing: const StatusBadge(label: 'Active', icon: Icons.check),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Communication & WhatsApp
              const Text('WhatsApp & Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AvotekCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                      title: const Text('Avotek WhatsApp Bot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Access exam results, question of the day, and airtime via WhatsApp Cloud API', style: TextStyle(fontSize: 12)),
                      trailing: const StatusBadge(label: 'Connected', icon: Icons.check),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WhatsApp Cloud integration is linked to your Avotek balance.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B)),
                      title: const Text('Academic & Exam Deadlines', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Receive push alerts when WAEC, NECO, and JAMB publish announcements', style: TextStyle(fontSize: 12)),
                      trailing: const StatusBadge(label: 'Enabled', icon: Icons.check),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    auth.signOut();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out of Avotek', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
