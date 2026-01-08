import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/homescreen.dart';
import '../forum/community_forum_screen.dart';
import '../report/report_case_screen.dart';
import '../profile/profile_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _currentNavIndex = 0;
  Stream<int>? _tick;
  // inline new-task form state
  bool _showNewTaskForm = false;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _tick = Stream<int>.periodic(const Duration(seconds: 1), (x) => x)
        .asBroadcastStream();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('tasks')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? {},
        toFirestore: (data, _) => data,
      );

  Future<void> _submitInlineTask() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack('Please login to add tasks', isError: true);
      return;
    }
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('Please enter a task title', isError: true);
      return;
    }
    final durationText = _durationCtrl.text.trim();
    final duration = int.tryParse(durationText);
    if (duration == null || duration < 1) {
      _showSnack('Please enter a valid duration (minimum 1 minute)',
          isError: true);
      return;
    }
    final now = DateTime.now();
    await _tasksRef(user.uid).add({
      'title': title,
      'note': _noteCtrl.text.trim(),
      'durationMin': duration,
      'startAt': Timestamp.fromDate(now),
      'status': 'in-progress',
      'createdAt': FieldValue.serverTimestamp(),
      'restartCount': 0,
    });
    if (!mounted) return;
    setState(() {
      _showNewTaskForm = false;
      _titleCtrl.clear();
      _noteCtrl.clear();
      _durationCtrl.text = '30';
    });
    _showSnack('Task added');
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool _isExpired(Timestamp startAt, int durationMin) {
    final end = startAt.toDate().add(Duration(minutes: durationMin));
    return DateTime.now().isAfter(end);
  }

  double _progress(Timestamp startAt, int durationMin) {
    final start = startAt.toDate();
    final total = Duration(minutes: durationMin).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    if (elapsed <= 0) return 0;
    final value = elapsed / total;
    return value.clamp(0.0, 1.0);
  }

  Duration _remaining(Timestamp startAt, int durationMin) {
    final end = startAt.toDate().add(Duration(minutes: durationMin));
    final now = DateTime.now();
    if (now.isAfter(end)) return Duration.zero;
    return end.difference(now);
  }

  Future<void> _completeTask(DocumentReference ref) async {
    await ref.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _restartTask(DocumentReference ref) async {
    await ref.update({
      'startAt': Timestamp.fromDate(DateTime.now()),
      'status': 'in-progress',
      'restartCount': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        title: const Text('To-Do Tasks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // using inline add form instead of app bar action
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header similar to report_case_screen style
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF56CCF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3498DB).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.timer,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan • Focus • Finish',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Create timed tasks and track completion. Expired tasks can be restarted.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Inline add form/button will appear under the list (or placeholder)

              const Text(
                'Your Tasks',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),

              if (user == null) ...[
                _emptyMessage('Sign in to create and track tasks'),
              ] else ...[
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _tasksRef(user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _emptyMessage('No tasks yet. Create your first task'),
                          const SizedBox(height: 12),
                          _showNewTaskForm
                              ? _buildNewTaskFormCard()
                              : _buildAddTaskButton(),
                        ],
                      );
                    }

                    final docs = snap.data!.docs;
                    return StreamBuilder<int>(
                      stream: _tick,
                      builder: (context, _) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _showNewTaskForm
                                    ? _buildNewTaskFormCard()
                                    : _buildAddTaskButton(),
                              );
                            }
                            final doc = docs[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildTaskCard(doc),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] ?? '') as String;
    final note = (data['note'] ?? '') as String;
    final durationMin = (data['durationMin'] ?? 30) as int;
    final startAt = (data['startAt'] as Timestamp?);
    final status = (data['status'] ?? 'in-progress') as String;

    final isCompleted = status == 'completed';
    final isExpired =
        !isCompleted && startAt != null && _isExpired(startAt, durationMin);
    final remaining =
        startAt == null ? Duration.zero : _remaining(startAt, durationMin);
    final progress = startAt == null ? 0.0 : _progress(startAt, durationMin);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: isCompleted ? 1.0 : progress,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(
                    isCompleted
                        ? const Color(0xFF00D4A4)
                        : (isExpired
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF3498DB)),
                  ),
                  strokeWidth: 6,
                ),
                Center(
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isExpired
                            ? Icons.warning_amber_rounded
                            : Icons.timer),
                    color: isCompleted
                        ? const Color(0xFF00D4A4)
                        : (isExpired
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF3498DB)),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isCompleted
                                ? const Color(0xFF00D4A4)
                                : (isExpired
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFFFFBE0B)))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed'
                            : (isExpired ? 'Incomplete' : 'In progress'),
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF00D4A4)
                              : (isExpired
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFFFFBE0B)),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted
                          ? 'Done'
                          : (isExpired
                              ? 'Time up'
                              : _formatRemaining(remaining)),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? const Color(0xFF00D4A4)
                            : (isExpired
                                ? const Color(0xFFFF6B6B)
                                : Colors.black87),
                      ),
                    ),
                    const Spacer(),
                    if (!isCompleted && !isExpired)
                      TextButton(
                        onPressed: () => _completeTask(doc.reference),
                        child: const Text('Mark Done'),
                      ),
                    if (isExpired)
                      TextButton(
                        onPressed: () => _restartTask(doc.reference),
                        child: const Text('Restart'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _showNewTaskForm = true),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3498DB),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildNewTaskFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g., 20 min meditation',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _durationCtrl,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 30',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitInlineTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child:
                      const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _showNewTaskForm = false),
                child: const Text('Cancel'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _emptyMessage(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info, color: Color(0xFF3498DB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
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

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF3498DB),
      ),
    );
  }
}
