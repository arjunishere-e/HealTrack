import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../home/homescreen.dart';
import '../forum/community_forum_screen.dart';
import '../report/report_case_screen.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  int _completedTasks = 0;
  int? _pressedNavIndex;

  static const Color emerald = Color(0xFF00D4A4);
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color pageBackground = Color(0xFFF4F6FB);
  static const Color shellBackground = Color(0xFFF9FBFF);

  String get _badgeLabel {
    if (_completedTasks >= 20) return 'Champion';
    if (_completedTasks >= 10) return 'Steady';
    if (_completedTasks >= 5) return 'Starter';
    if (_completedTasks >= 1) return 'Newcomer';
    return 'Getting Started';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  void _promptPasswordReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
            'A password reset email will be sent to your email address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPasswordReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendPasswordReset() async {
    if (_user?.email == null) return;
    try {
      await _auth.sendPasswordResetEmail(email: _user!.email!);
      _showSnack('Password reset email sent!');
    } catch (e) {
      _showSnack('Error: ${e.toString()}', isError: true);
    }
  }

  BoxDecoration _softPanel({
    required List<Color> colors,
    required Color borderColor,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.14),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          title: const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: shellBackground,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _buildBottomNavBar(),
      );
    }

    final displayName = _user?.displayName ?? 'User';
    final email = _user?.email ?? 'Not available';

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: shellBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _softPanel(
                  colors: const [Color(0xFFEEF4FF), Color(0xFFE2ECFF)],
                  borderColor: const Color(0xFFCBDCF8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E8EDC),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFF21334F),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Color(0xFF61718C),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Section
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.person,
                label: 'Username',
                value: displayName,
              ),
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.email,
                label: 'Email',
                value: email,
              ),
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.lock,
                label: 'Password',
                value: 'Hidden for security',
                onIconTap: _promptPasswordReset,
              ),
              const SizedBox(height: 24),

              // Progress & Badges
              Text(
                'Progress & Badges',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user?.uid)
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snap) {
                  int completed = 0;
                  int incomplete = 0;

                  if (snap.hasData) {
                    for (final doc in snap.data!.docs) {
                      final data = doc.data();
                      final status =
                          (data['status'] ?? 'in-progress') as String;
                      if (status == 'completed') {
                        completed++;
                      } else {
                        incomplete++;
                      }
                    }
                  }

                  _completedTasks = completed;
                  final total = completed + incomplete;
                  final progress =
                      total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _softPanel(
                      colors: const [Color(0xFFF7F1FB), Color(0xFFECE1F7)],
                      borderColor: const Color(0xFFD9C8EC),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A63D2),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.emoji_events,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _badgeLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2E2142),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Earned by completing tasks',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C6182),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                title: 'Completed',
                                value: completed.toString(),
                                color: emerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                title: 'Pending',
                                value: incomplete.toString(),
                                color: const Color(0xFFFFBE0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.65),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF8A63D2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C6182),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD95F39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onIconTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softPanel(
        colors: const [Color(0xFFFFFBF7), Color(0xFFF9F4EF)],
        borderColor: const Color(0xFFF0DDD1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onIconTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: onIconTap != null
                    ? const Color(0xFFDCE8FF)
                    : const Color(0xFFF2EEE8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                onIconTap != null ? Icons.edit : icon,
                color: onIconTap != null
                    ? const Color(0xFF426AA6)
                    : const Color(0xFF7A5A50),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A7B72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      {required String title, required String value, required Color color}) {
    final borderColor = color.withOpacity(0.24);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.report, 1),
          _buildNavItem(Icons.groups, 2),
          _buildNavItem(Icons.person, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = index == 3;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedNavIndex = index),
      onTapCancel: () => setState(() => _pressedNavIndex = null),
      onTapUp: (_) {
        setState(() => _pressedNavIndex = null);
      },
      onTap: () {
        HapticFeedback.lightImpact();
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ReportCaseScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const CommunityForumScreen()),
          );
        }
      },
      child: AnimatedScale(
        scale: _pressedNavIndex == index ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black,
      ),
    );
  }
}
