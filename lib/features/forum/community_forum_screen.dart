import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../home/homescreen.dart';
import '../profile/profile_screen.dart';
import '../report/report_case_screen.dart';
import 'community_detail_screen.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  static const Color emerald = Color(0xFF00D4A4);
  static const Color pageBackground = Color(0xFFF4F6FB);
  static const Color shellBackground = Color(0xFFF9FBFF);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int? _pressedNavIndex;

  Map<String, Color> _communityPalette(int index) {
    switch (index % 3) {
      case 0:
        return {
          'background': const Color(0xFFFFF4ED),
          'border': const Color(0xFFF1C9B5),
          'block': const Color(0xFFF7CDB8),
          'iconBackground': const Color(0xFFD95F39),
          'iconTint': Colors.white,
          'chipBackground': const Color(0xFFFFE5D8),
          'chipText': const Color(0xFF9C442B),
          'title': const Color(0xFF3C1F18),
          'body': const Color(0xFF7A5A50),
        };
      case 1:
        return {
          'background': const Color(0xFFEEF4FF),
          'border': const Color(0xFFCBDCF8),
          'block': const Color(0xFFD7E5FF),
          'iconBackground': const Color(0xFF5E8EDC),
          'iconTint': Colors.white,
          'chipBackground': const Color(0xFFDCE8FF),
          'chipText': const Color(0xFF426AA6),
          'title': const Color(0xFF21334F),
          'body': const Color(0xFF61718C),
        };
      default:
        return {
          'background': const Color(0xFFF3F7EC),
          'border': const Color(0xFFD4DECA),
          'block': const Color(0xFFE0EBCF),
          'iconBackground': const Color(0xFF6D8B45),
          'iconTint': Colors.white,
          'chipBackground': const Color(0xFFE6F0D8),
          'chipText': const Color(0xFF526B31),
          'title': const Color(0xFF2E3524),
          'body': const Color(0xFF6E7565),
        };
    }
  }

  void _addCommunity() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a community',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Community name',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emerald,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  if (name.isEmpty || desc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final user = _auth.currentUser;
                    if (user == null) return;

                    await _firestore.collection('communities').add({
                      'name': name,
                      'description': desc,
                      'creator': user.uid,
                      'creatorName': user.displayName ?? 'Anonymous',
                      'memberCount': 1,
                      'members': [user.uid],
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Community created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Community',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: shellBackground,
        foregroundColor: AppTheme.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('communities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final communities = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroCard(),
                  const SizedBox(height: 18),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  if (communities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: shellBackground,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE0E6F2)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCE8FF),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.people,
                                    size: 34, color: Color(0xFF426AA6)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No communities yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create the first space and start a calmer, more supportive conversation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: communities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = communities[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _communityCard(doc.id, data, index);
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5E8EDC),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Community',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        onPressed: _addCommunity,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFE2ECFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCBDCF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E8EDC).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                width: 132,
                height: 116,
                decoration: const BoxDecoration(
                  color: Color(0xFFC7DAFF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              right: 24,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E8EDC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.forum_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share. Support. Grow.',
                          style: TextStyle(
                            color: Color(0xFF21334F),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Join communities, ask questions, and uplift others on the journey.',
                          style: TextStyle(
                            color: Color(0xFF61718C),
                            fontSize: 13,
                            height: 1.4,
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

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search communities...',
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: shellBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE0E6F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE0E6F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFFCBDCF8), width: 1.5),
              ),
            ),
            onChanged: (q) {
              // Placeholder search; keep simple for now
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6E3BF),
            foregroundColor: const Color(0xFF526B31),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _addCommunity,
          icon: const Icon(Icons.add, color: Color(0xFF526B31)),
          label: const Text(
            'Create',
            style: TextStyle(
              color: Color(0xFF526B31),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _communityCard(
      String communityId, Map<String, dynamic> data, int index) {
    final palette = _communityPalette(index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              communityId: communityId,
              communityName: data['name'] ?? 'Community',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: palette['background'],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette['border']!),
          boxShadow: [
            BoxShadow(
              color: palette['iconBackground']!.withValues(alpha: 0.08),
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
                  width: 108,
                  height: 94,
                  decoration: BoxDecoration(
                    color: palette['block']!,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: palette['iconBackground']!,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.groups_rounded,
                              color: palette['iconTint']!, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Community',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: palette['title']!,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: palette['chipBackground']!,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${data['memberCount'] ?? 0} members',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: palette['chipText']!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: palette['chipText']!, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette['body']!,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    final isSelected = index == 2;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedNavIndex = index),
      onTapCancel: () => setState(() => _pressedNavIndex = null),
      onTapUp: (_) => setState(() => _pressedNavIndex = null),
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
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
}
