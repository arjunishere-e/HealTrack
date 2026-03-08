import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../report/report_case_screen.dart';
import '../rehab_centers/rehab_centers_screen.dart';
import '../forum/community_forum_screen.dart';
import '../stories/success_stories_screen.dart';
import '../tasks/todo_screen.dart';
import '../chatbot/counsellors_screen.dart';
import '../profile/find_you_screen.dart';
import '../profile/diary_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final PageController _bannerController =
      PageController(viewportFraction: 0.94);
  final Random _random = Random();
  int _currentBannerPage = 0;
  int _quoteIndex = 0;
  late String _userName = '';
  bool _isLoadingStreak = true;
  bool _journeyStarted = false;
  final Set<String> _cleanDates = <String>{};
  bool _hasLoadedStreak = false;

  final List<Map<String, String>> _motivationalQuotes = const [
    {
      'label': 'Daily focus',
      'quote': 'One clear choice today is enough to change your direction.',
      'support':
          'Progress does not need to be loud. It only needs to continue.',
    },
    {
      'label': 'Keep going',
      'quote':
          'Healing grows in ordinary days that you decide not to give up on.',
      'support': 'Small steady steps are still strong steps.',
    },
    {
      'label': 'For today',
      'quote':
          'You do not need a perfect week. You need one honest decision now.',
      'support': 'Protect this moment first, then build the next one.',
    },
    {
      'label': 'Recovery note',
      'quote':
          'Every time you choose yourself, you make tomorrow a little safer.',
      'support': 'Consistency matters more than intensity.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _quoteIndex = _random.nextInt(_motivationalQuotes.length);
    _startAutoScroll();
    _loadUserName();
    _loadStreak();
  }

  void _pickNextQuote() {
    if (_motivationalQuotes.length < 2) {
      return;
    }

    var nextIndex = _quoteIndex;
    while (nextIndex == _quoteIndex) {
      nextIndex = _random.nextInt(_motivationalQuotes.length);
    }

    if (!mounted) return;
    setState(() {
      _quoteIndex = nextIndex;
    });
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _userName = 'there';
      });
      return;
    }

    try {
      var nextName = user.displayName?.trim() ?? '';

      if (nextName.isEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        nextName = (doc.data()?['displayName'] as String?)?.trim() ?? '';
      }

      if (!mounted) return;
      setState(() {
        _userName = nextName.isEmpty ? 'there' : nextName;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'there';
      });
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_bannerController.hasClients) {
        return;
      }

      final nextPage = (_currentBannerPage + 1) % 2;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  Future<void> _loadStreak() async {
    if (_hasLoadedStreak) return;
    _hasLoadedStreak = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingStreak = false;
        _journeyStarted = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final storedDates = (data['cleanDates'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet();

      _cleanDates
        ..clear()
        ..addAll(storedDates);

      if (!mounted) return;
      setState(() {
        _journeyStarted = data['started'] == true || _cleanDates.isNotEmpty;
        cleanDays = _computeCurrentStreak();
        _isLoadingStreak = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _journeyStarted = _cleanDates.isNotEmpty;
        cleanDays = _computeCurrentStreak();
        _isLoadingStreak = false;
      });
    }
  }

  Future<void> _markTodayClean() async {
    final key = _dateKey(DateTime.now());
    if (_cleanDates.contains(key)) {
      return;
    }

    _cleanDates.add(key);
    if (mounted) {
      setState(() {
        _journeyStarted = true;
        cleanDays = _computeCurrentStreak();
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'cleanDates': _cleanDates.toList()..sort(),
      'lastUpdatedDate': key,
      'started': true,
    }, SetOptions(merge: true));
  }

  Future<void> _startJourney() async {
    if (mounted) {
      setState(() {
        _journeyStarted = true;
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'started': true,
      'cleanDates': _cleanDates.toList()..sort(),
    }, SetOptions(merge: true));
  }

  int _computeCurrentStreak() {
    int streak = 0;
    DateTime day = DateTime.now();
    while (_cleanDates.contains(_dateKey(day))) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> features = [
    {
      "icon": Icons.report,
      "title": "Report Case",
      "description": "Report substance abuse cases anonymously",
      "screen": const ReportCaseScreen(),
    },
    {
      "icon": Icons.local_hospital,
      "title": "Rehab Centers",
      "description": "Find nearby rehabilitation centers",
      "screen": const RehabCentersScreen(),
    },
    {
      "icon": Icons.group,
      "title": "Community Forum",
      "description": "Connect with others on the same journey",
      "screen": const CommunityForumScreen(),
    },
    {
      "icon": Icons.star,
      "title": "Success Stories",
      "description": "Read inspiring recovery stories",
      "screen": const SuccessStoriesScreen(),
    },
    {
      "icon": Icons.task,
      "title": "To-Do",
      "description": "Track your daily recovery tasks",
      "screen": const TodoScreen(),
    },
    {
      "icon": Icons.emergency_share,
      "title": "Counsellors",
      "description": "Connect with professional counsellors",
      "screen": const CounsellorsScreen(),
    },
    {
      "icon": Icons.self_improvement,
      "title": "Find You",
      "description": "Self-assessment and guidance tools",
      "screen": const FindYouScreen(),
    },
    {
      "icon": Icons.book,
      "title": "Diary",
      "description": "Journal your recovery journey",
      "screen": const DiaryScreen(),
    },
  ];

  // Simulated streak data - days clean
  int cleanDays = 25;

  List<Map<String, dynamic>> get _quickActions => features.take(4).toList();

  Map<String, dynamic> get _findYouFeature =>
      features.firstWhere((feature) => feature['title'] == 'Find You');

  List<Map<String, dynamic>> get _supportTools => features
      .skip(4)
      .where((feature) => feature['title'] != 'Find You')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            SizedBox(
              height: 182,
              child: PageView(
                controller: _bannerController,
                onPageChanged: (index) {
                  _currentBannerPage = index;
                  if (index == 0) {
                    _pickNextQuote();
                  }
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildChallengeBanner(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildMotivationBanner(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSectionHeader(
                'Recovery journey', 'Track consistency without pressure'),
            const SizedBox(height: 12),
            if (_isLoadingStreak)
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(minHeight: 6),
              )
            else if (!_journeyStarted)
              _buildJourneyStarterCard()
            else ...[
              _buildStreakCalendar(),
              const SizedBox(height: 10),
              _buildUpdateProgressLink(),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Quick actions', 'Start from what you need today'),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Expert tools', 'Focused support spaces across the app'),
            const SizedBox(height: 12),
            _buildSupportToolsPanel(),
            const SizedBox(height: 22),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 54),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _findYouFeature['screen'] as Widget,
            ),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          child: const Icon(Icons.self_improvement_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildChallengeBanner() {
    final quote = _motivationalQuotes[_quoteIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF14345A), Color(0xFF224F82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF2B5C8C)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2742).withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B446F),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_quote_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          quote['label']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quote['quote']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quote['support']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7E6F4),
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.wb_twilight_rounded,
                color: Color(0xFF14345A),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F7EC), Color(0xFFE4EDDA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD4DECA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D8B45).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 104,
                height: 98,
                decoration: const BoxDecoration(
                  color: Color(0xFFD6E3BF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              right: 18,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6E3BF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Progress snapshot',
                            style: TextStyle(
                              color: Color(0xFF526B31),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '$cleanDays day${cleanDays == 1 ? '' : 's'} of visible effort',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2E3524),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Recovery is built from repeated, ordinary days. Keep momentum calm and steady.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF6E7565),
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D8B45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.self_improvement,
                            color: Colors.white, size: 24),
                        SizedBox(height: 2),
                        Text(
                          'steady',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 3));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (index) {
            final date = startDate.add(Duration(days: index));
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isClean = _cleanDates.contains(_dateKey(date));
            final isPast =
                date.isBefore(DateTime(today.year, today.month, today.day));
            final isMissed = isPast && !isClean;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isToday ? _markTodayClean : null,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isToday
                            ? (isClean
                                ? const Color(0xFF00D4A4)
                                : AppTheme.textPrimary)
                            : isMissed
                                ? const Color(0xFFFF6B6B)
                                : Colors.white,
                        border: Border.all(
                          color: !isToday && isClean
                              ? const Color(0xFF00D4A4)
                              : !isToday && isMissed
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : (isClean
                                    ? const Color(0xFF00D4A4)
                                    : isMissed
                                        ? Colors.white
                                        : Colors.grey.shade700),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isClean && !isToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00D4A4),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildJourneyStarterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F1FB), Color(0xFFECE1F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD9C8EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF8A63D2),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Your Journey',
                  style: TextStyle(
                    color: Color(0xFF2E2142),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Build a daily clean streak. Tap start and check in every day!',
                  style: TextStyle(color: Color(0xFF6C6182), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _showJourneyIntro();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A63D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start'),
          )
        ],
      ),
    );
  }

  Future<void> _showJourneyIntro() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              const Center(
                child: Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 40),
              ),
              const SizedBox(height: 12),
              const Text(
                'Build Your Clean Streak',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Like Duolingo streaks, checking in daily strengthens your recovery habit. Each day you stay clean, mark it — watch your streak grow!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text('How it works:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                  '• Tap the button to mark today clean\n• Green days show your progress\n• The big number shows your current streak\n• Miss a day? The streak resets — keep going!'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _startJourney();
                        if (mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Journey started! Mark today to begin your streak.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4A4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start Journey'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateProgressLink() {
    return GestureDetector(
      onTap: _showMonthlyCalendarModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.panelTint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Update progress',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: const [
                Text(
                  'Open calendar',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_userName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.panelTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Today ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A calmer layout for your support tools, daily rhythm, and next step.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: AppTheme.textPrimary, size: 24),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final primaryAction = _quickActions[0];
    final secondaryActions = _quickActions.sublist(1, 3);
    final insightAction = _quickActions[3];

    return Column(
      children: [
        _buildPrimaryQuickAction(primaryAction),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCompactQuickAction(secondaryActions[0], 0)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactQuickAction(secondaryActions[1], 1)),
          ],
        ),
        const SizedBox(height: 12),
        _buildInsightQuickAction(insightAction),
      ],
    );
  }

  Widget _buildPrimaryQuickAction(Map<String, dynamic> feature) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => feature['screen'] as Widget),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4ED), Color(0xFFFFE3D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFF1C9B5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD77953).withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 134,
                  height: 124,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4B08A),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                right: 34,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7CDB8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Primary action',
                              style: TextStyle(
                                color: Color(0xFF7B3726),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            feature['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF3C1F18),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feature['description'] as String,
                            style: const TextStyle(
                              color: Color(0xFF7A5A50),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Text(
                                'Open now',
                                style: TextStyle(
                                  color: Color(0xFF9C442B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF9C442B),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD95F39),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _compactPalette(int index) {
    switch (index % 3) {
      case 0:
        return {
          'background': const Color(0xFFEEF4FF),
          'backgroundEnd': const Color(0xFFE2ECFF),
          'border': const Color(0xFFCBDCF8),
          'panel': const Color(0xFFC7DAFF),
          'iconBackground': const Color(0xFF5E8EDC),
          'icon': Colors.white,
          'title': const Color(0xFF21334F),
          'body': const Color(0xFF61718C),
          'chip': const Color(0xFFD7E5FF),
          'chipText': const Color(0xFF426AA6),
        };
      case 1:
        return {
          'background': const Color(0xFFF4F0FF),
          'backgroundEnd': const Color(0xFFECE5FF),
          'border': const Color(0xFFD8CEF9),
          'panel': const Color(0xFFD9CEFF),
          'iconBackground': const Color(0xFF7E67CC),
          'icon': Colors.white,
          'title': const Color(0xFF2F2445),
          'body': const Color(0xFF71658B),
          'chip': const Color(0xFFE4DBFF),
          'chipText': const Color(0xFF6A56B5),
        };
      default:
        return {
          'background': const Color(0xFFF3F7EC),
          'backgroundEnd': const Color(0xFFE8F0DE),
          'border': const Color(0xFFD4DECA),
          'panel': const Color(0xFFD6E3BF),
          'iconBackground': const Color(0xFF6D8B45),
          'icon': Colors.white,
          'title': const Color(0xFF2E3524),
          'body': const Color(0xFF6E7565),
          'chip': const Color(0xFFE0EBCF),
          'chipText': const Color(0xFF526B31),
        };
    }
  }

  Map<String, Color> _supportPalette(int index) {
    switch (index % 3) {
      case 0:
        return {
          'background': const Color(0xFFFFF4ED),
          'border': const Color(0xFFF1C9B5),
          'panel': const Color(0xFFF7CDB8),
          'iconBackground': const Color(0xFFD95F39),
          'title': const Color(0xFF3C1F18),
          'body': const Color(0xFF7A5A50),
          'labelBackground': const Color(0xFFFFE5D8),
          'labelText': const Color(0xFF9C442B),
        };
      case 1:
        return {
          'background': const Color(0xFFEEF4FF),
          'border': const Color(0xFFCBDCF8),
          'panel': const Color(0xFFD7E5FF),
          'iconBackground': const Color(0xFF5E8EDC),
          'title': const Color(0xFF21334F),
          'body': const Color(0xFF61718C),
          'labelBackground': const Color(0xFFDCE8FF),
          'labelText': const Color(0xFF426AA6),
        };
      default:
        return {
          'background': const Color(0xFFF3F7EC),
          'border': const Color(0xFFD4DECA),
          'panel': const Color(0xFFE0EBCF),
          'iconBackground': const Color(0xFF6D8B45),
          'title': const Color(0xFF2E3524),
          'body': const Color(0xFF6E7565),
          'labelBackground': const Color(0xFFE6F0D8),
          'labelText': const Color(0xFF526B31),
        };
    }
  }

  Widget _buildCompactQuickAction(Map<String, dynamic> feature, int index) {
    final palette = _compactPalette(index);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => feature['screen'] as Widget),
      ),
      child: Container(
        height: 178,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette['background']!, palette['backgroundEnd']!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette['border']!),
          boxShadow: [
            BoxShadow(
              color: palette['iconBackground']!.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 92,
                  height: 82,
                  decoration: BoxDecoration(
                    color: palette['panel']!,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette['iconBackground']!,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: palette['icon']!,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette['chip']!,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Quick action',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette['chipText']!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette['title']!,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette['body']!,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightQuickAction(Map<String, dynamic> feature) {
    final palette = _compactPalette(2);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => feature['screen'] as Widget),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette['background']!, palette['backgroundEnd']!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette['border']!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 106,
                  height: 100,
                  decoration: BoxDecoration(
                    color: palette['panel']!,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: palette['iconBackground']!,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: palette['icon']!,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Read and reflect',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette['chipText']!,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: palette['title']!,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette['body']!,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded,
                        color: palette['chipText']!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportToolsPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF0DDD1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: const [
                Icon(Icons.tune_rounded, size: 18, color: Color(0xFF9C442B)),
                SizedBox(width: 8),
                Text(
                  'Daily and professional support',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9C442B),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_supportTools.length, (index) {
            final feature = _supportTools[index];
            final labels = ['Routine', 'Professional', 'Private'];
            return Column(
              children: [
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(height: 1, color: Color(0xFFF0DDD1)),
                  ),
                _buildSupportToolRow(
                  feature,
                  labels[index % labels.length],
                  index,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupportToolRow(
      Map<String, dynamic> feature, String label, int index) {
    final palette = _supportPalette(index);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => feature['screen'] as Widget),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette['background']!,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette['border']!),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: palette['iconBackground']!,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: palette['title']!,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: palette['labelBackground']!,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette['labelText']!,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette['body']!,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: palette['labelText']!),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthlyCalendarModal() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _getMonthFullName(now.month) + ' ${now.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Streak: $cleanDays days',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Weekday headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) => SizedBox(
                            width: 40,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: firstWeekday - 1 + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday - 1) {
                      return const SizedBox.shrink();
                    }
                    final day = index - firstWeekday + 2;
                    final date = DateTime(now.year, now.month, day);
                    final dateKey = _dateKey(date);
                    final isToday = date.day == now.day;
                    final isClean = _cleanDates.contains(dateKey);
                    final isPast =
                        date.isBefore(DateTime(now.year, now.month, now.day));

                    Color backgroundColor;
                    Color textColor;
                    Color? borderColor;

                    if (isToday) {
                      backgroundColor =
                          isClean ? const Color(0xFF00D4A4) : Colors.black;
                      textColor = Colors.white;
                      borderColor = null;
                    } else if (isPast) {
                      if (isClean) {
                        backgroundColor = const Color(0xFF00D4A4);
                        textColor = Colors.white;
                        borderColor = null;
                      } else {
                        backgroundColor = const Color(0xFFFF6B6B);
                        textColor = Colors.white;
                        borderColor = null;
                      }
                    } else {
                      // Future days
                      backgroundColor = Colors.white;
                      textColor = Colors.grey.shade700;
                      borderColor = Colors.grey.shade300;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: borderColor != null
                            ? Border.all(color: borderColor, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(const Color(0xFF00D4A4), 'Clean day'),
                    const SizedBox(width: 16),
                    _buildLegendItem(const Color(0xFFFF6B6B), 'Missed day'),
                  ],
                ),
                const SizedBox(height: 24),
                // Mark today button
                ElevatedButton.icon(
                  onPressed: _cleanDates.contains(_dateKey(now))
                      ? null
                      : () async {
                          await _markTodayClean();
                          setModalState(() {}); // Update modal UI immediately
                        },
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    _cleanDates.contains(_dateKey(now))
                        ? 'Marked for today — great!'
                        : 'I was clean today 🙂',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cleanDates.contains(_dateKey(now))
                        ? Colors.grey.shade300
                        : const Color(0xFF00D4A4),
                    foregroundColor: _cleanDates.contains(_dateKey(now))
                        ? Colors.black54
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportCaseScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CommunityForumScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          setState(() {
            _currentNavIndex = index;
          });
        }
      },
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
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  String _getMonthFullName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}
