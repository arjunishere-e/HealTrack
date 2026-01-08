import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/auth_service.dart';
import '../../routes/app_routes.dart';
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
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  late String _userName = '';
  final AuthService _authService = AuthService();
  // Streak tracking state
  bool _isLoadingStreak = true;
  bool _journeyStarted = false;
  final Set<String> _cleanDates = <String>{};
  bool _hasLoadedStreak = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadUserName();
    _loadStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we haven't loaded yet or if explicitly needed
    if (!_hasLoadedStreak) {
      _loadStreak();
    }
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get displayName from FirebaseAuth (no buffering)
      String displayName = user.displayName ?? 'User';

      setState(() {
        _userName = displayName;
      });
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _bannerController.hasClients) {
        _currentBannerPage = (_currentBannerPage + 1) % 2;
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  // ---------- Streak Tracking: Firestore helpers ----------
  DocumentReference<Map<String, dynamic>>? get _streakDocRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('streak');
  }

  Future<void> _loadStreak() async {
    try {
      final ref = _streakDocRef;
      if (ref == null) {
        setState(() => _isLoadingStreak = false);
        return;
      }
      final snap = await ref.get();
      if (!snap.exists) {
        _journeyStarted = false;
        _cleanDates.clear();
      } else {
        final data = snap.data() ?? {};
        _journeyStarted = (data['started'] ?? false) as bool;
        final entries = (data['entries'] as Map<String, dynamic>?) ?? {};
        _cleanDates
          ..clear()
          ..addAll(entries.entries
              .where((e) => e.value == true)
              .map((e) => e.key.toString()));
      }
      cleanDays = _computeCurrentStreak();
      _hasLoadedStreak = true;
    } catch (_) {
      // leave defaults on error
    } finally {
      if (mounted) setState(() => _isLoadingStreak = false);
    }
  }

  Future<void> _startJourney() async {
    // Immediately reflect in UI
    setState(() {
      _journeyStarted = true;
    });
    // Persist if user is logged in
    final ref = _streakDocRef;
    if (ref != null) {
      await ref.set({
        'started': true,
        'createdAt': FieldValue.serverTimestamp(),
        'entries': <String, bool>{},
      }, SetOptions(merge: true));
    }
  }

  Future<void> _markTodayClean() async {
    final ref = _streakDocRef;
    if (ref == null) return;
    final key = _dateKey(DateTime.now());
    if (_cleanDates.contains(key)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Already marked clean today. Great job!')),
        );
      }
      return;
    }
    await ref.set({
      'entries': {key: true},
      'lastUpdatedDate': key,
      'started': true,
    }, SetOptions(merge: true));
    _cleanDates.add(key);
    setState(() {
      cleanDays = _computeCurrentStreak();
    });
  }

  int _computeCurrentStreak() {
    int streak = 0;
    DateTime d = DateTime.now();
    while (_cleanDates.contains(_dateKey(d))) {
      streak += 1;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  static const Color emerald = Color(0xFF00D4A4);
  static const Color primaryBlue = Color(0xFF0066FF);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [
            // ---------------- HEADER ----------------
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $_userName",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Today ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------------- DAILY CHALLENGE BANNER ----------------
            SizedBox(
              height: 160,
              child: PageView(
                controller: _bannerController,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildChallengeBanner(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMotivationBanner(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- STREAK / JOURNEY ----------------
            if (_isLoadingStreak)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (!_journeyStarted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildJourneyStarterCard(),
              )
            else ...[
              _buildStreakCalendar(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildUpdateProgressLink(),
              ),
            ],

            const SizedBox(height: 20),

            // ---------------- FEATURE CARDS ----------------
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: features.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final isIconLeft = index % 2 == 0;
                final colors = [
                  [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFFF8E8E)
                  ], // Bright coral red
                  [
                    const Color(0xFF4ECDC4),
                    const Color(0xFF44A08D)
                  ], // Turquoise teal
                  [
                    const Color(0xFFFFBE0B),
                    const Color(0xFFFFD60A)
                  ], // Vibrant yellow
                  [
                    const Color(0xFF9B59B6),
                    const Color(0xFFBB6BD9)
                  ], // Purple violet
                  [
                    const Color(0xFF3498DB),
                    const Color(0xFF56CCF2)
                  ], // Sky blue
                  [
                    const Color(0xFFFF6F91),
                    const Color(0xFFFF9A9E)
                  ], // Pink rose
                  [
                    const Color(0xFF00D4A4),
                    const Color(0xFF2ADCA8)
                  ], // Bright emerald
                  [
                    const Color(0xFFFF5722),
                    const Color(0xFFFF7043)
                  ], // Orange flame
                ];
                final colorPair = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              features[index]["screen"] as Widget,
                        ),
                      );
                    },
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: colorPair,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            color: colorPair[0].withOpacity(0.45),
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          if (isIconLeft) ...[
                            // Icon on left
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  features[index]["icon"] as IconData,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(width: 22),
                            // Text on right
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    features[index]["title"] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    features[index]["description"] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.95),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Text on left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    features[index]["title"] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    features[index]["description"] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.95),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            // Icon on right
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  features[index]["icon"] as IconData,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildChallengeBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB388FF), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Daily\nchallenge",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Do your plan before 09:00 AM",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, emerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            "Stay Strong!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$cleanDays days clean",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (index) {
            final date = startOfWeek.add(Duration(days: index));
            final isToday = date.day == today.day;
            final isClean = _cleanDates.contains(_dateKey(date));

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
                            ? (isClean ? const Color(0xFF00D4A4) : Colors.black)
                            : Colors.white,
                        border: Border.all(
                          color: !isToday && isClean
                              ? const Color(0xFF00D4A4)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "${date.day}",
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : (isClean
                                    ? const Color(0xFF00D4A4)
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
          colors: [Color(0xFF00D4A4), Color(0xFF2ADCA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white, size: 42),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Your Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Build a daily clean streak. Tap start and check in every day!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Show instructions; actual start is inside the sheet's button
              await _showJourneyIntro();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00D4A4),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'update progress',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 18),
        ],
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
                    final isFuture =
                        date.isAfter(DateTime(now.year, now.month, now.day));

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

  Widget _buildMarkTodayButton() {
    final todayMarked = _cleanDates.contains(_dateKey(DateTime.now()));
    return ElevatedButton.icon(
      onPressed: todayMarked ? null : _markTodayClean,
      icon: const Icon(Icons.check_circle),
      label: Text(
          todayMarked ? 'Marked for today — great!' : 'I was clean today 🙂'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            todayMarked ? Colors.grey.shade300 : const Color(0xFF00D4A4),
        foregroundColor: todayMarked ? Colors.black54 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
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
