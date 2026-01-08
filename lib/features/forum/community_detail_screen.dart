import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  static const Color emerald = Color(0xFF00D4A4);
  static const Color primaryBlue = Color(0xFF0066FF);

  // User color palette for consistent per-user colors
  static const List<Color> userColorPalette = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Yellow
    Color(0xFF95E1D3), // Mint
    Color(0xFFF38181), // Pink
    Color(0xFFAA96DA), // Purple
    Color(0xFFFCBAAD), // Peach
    Color(0xFF6BCF7F), // Green
    Color(0xFF4D96FF), // Blue
    Color(0xFFFFB347), // Orange
  ];

  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isJoined = false;
  String? _replyingToId;
  Map<String, dynamic>? _replyingToData;
  final Map<String, Color> _userColorMap = {};
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Color _getUserColor(String userId) {
    if (!_userColorMap.containsKey(userId)) {
      _userColorMap[userId] =
          userColorPalette[_userColorMap.length % userColorPalette.length];
    }
    return _userColorMap[userId]!;
  }

  Future<void> _checkJoinStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .get();
      if (doc.exists) {
        final members = doc.data()?['members'] as List? ?? [];
        setState(() {
          _isJoined = members.contains(user.uid);
        });
      }
    } catch (e) {
      // Error loading join status
    }
  }

  Future<void> _joinCommunity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .update({
        'members': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
      });

      setState(() => _isJoined = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined community!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _leaveCommunity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .update({
        'members': FieldValue.arrayRemove([user.uid]),
        'memberCount': FieldValue.increment(-1),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You left the community'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reportMessage(String messageId, String authorName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report message by $authorName?'),
            const SizedBox(height: 16),
            const Text(
              'This message will be flagged for moderation review.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('communities')
                    .doc(widget.communityId)
                    .collection('posts')
                    .doc(messageId)
                    .update({
                  'reported': true,
                  'reportedAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message reported'),
                    backgroundColor: Colors.blue,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messageData = <String, Object>{
        'author': user.displayName ?? 'Anonymous',
        'authorId': user.uid,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'reactions': <String, List<String>>{},
      };

      if (_replyingToId != null) {
        messageData['replyingToId'] = _replyingToId as String;
        messageData['replyingToAuthor'] =
            _replyingToData?['author'] ?? 'Anonymous';
        messageData['replyingToContent'] = _replyingToData?['content'] ?? '';
      }

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('posts')
          .add(messageData);

      _messageController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToData = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('posts')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([user.uid]),
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildWhatsAppBackground() {
    return CustomPaint(
      painter: _ChatBackgroundPainter(),
      child: Container(
        color: const Color(0xFFECE5DD).withOpacity(0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.communityName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_isJoined)
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('communities')
                    .doc(widget.communityId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final memberCount = data['memberCount'] ?? 0;
                  return Text(
                    '$memberCount members',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal),
                  );
                },
              ),
          ],
        ),
        backgroundColor: emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isJoined)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Exit Community'),
                      content: const Text(
                          'Are you sure you want to leave this community?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _leaveCommunity();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Leave',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Exit Community',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isJoined
          ? Stack(
              children: [
                _buildWhatsAppBackground(),
                Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('communities')
                            .doc(widget.communityId)
                            .collection('posts')
                            .orderBy('timestamp', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: emerald),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final messages = snapshot.data?.docs ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Start the conversation!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final data =
                                  message.data() as Map<String, dynamic>;
                              final user = _auth.currentUser;
                              final isCurrentUser =
                                  user?.uid == data['authorId'];
                              final userColor = _getUserColor(data['authorId']);
                              final DateTime currentTs =
                                  (data['timestamp'] as Timestamp?)?.toDate() ??
                                      DateTime.now();
                              DateTime? previousTs;
                              if (index > 0) {
                                final prev = messages[index - 1].data()
                                    as Map<String, dynamic>;
                                previousTs =
                                    (prev['timestamp'] as Timestamp?)?.toDate();
                              }
                              final showDateSeparator = previousTs == null ||
                                  !_sameDay(previousTs, currentTs);
                              final initials = _initials(data['author'] ?? 'A');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    if (showDateSeparator)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                                child: Divider(height: 1)),
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${currentTs.day}/${currentTs.month}/${currentTs.year}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Expanded(
                                                child: Divider(height: 1)),
                                          ],
                                        ),
                                      ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment: isCurrentUser
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      children: [
                                        if (!isCurrentUser) ...[
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor:
                                                userColor.withOpacity(0.15),
                                            child: Text(
                                              initials,
                                              style: TextStyle(
                                                color: userColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Dismissible(
                                            key: Key(message.id),
                                            direction: isCurrentUser
                                                ? DismissDirection.endToStart
                                                : DismissDirection.startToEnd,
                                            confirmDismiss: (direction) async {
                                              setState(() {
                                                _replyingToId = message.id;
                                                _replyingToData = data;
                                              });
                                              HapticFeedback.mediumImpact();
                                              return false;
                                            },
                                            background: Container(
                                              alignment: isCurrentUser
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              padding: EdgeInsets.only(
                                                left: isCurrentUser ? 0 : 20,
                                                right: isCurrentUser ? 20 : 0,
                                              ),
                                              child: Icon(
                                                Icons.reply,
                                                color: Colors.grey.shade600,
                                                size: 24,
                                              ),
                                            ),
                                            child: GestureDetector(
                                              onLongPress: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) =>
                                                      Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 12),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const SizedBox(
                                                              height: 8),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Message Options',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .close),
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                          // Reactions
                                                          SizedBox(
                                                            height: 50,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                '👍',
                                                                '❤️',
                                                                '😂',
                                                                '😮',
                                                                '😢',
                                                                '🔥',
                                                              ]
                                                                  .map((emoji) =>
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          _addReaction(
                                                                              message.id,
                                                                              emoji);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          emoji,
                                                                          style:
                                                                              const TextStyle(fontSize: 32),
                                                                        ),
                                                                      ))
                                                                  .toList(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                          const Divider(
                                                              height: 1),
                                                          const SizedBox(
                                                              height: 12),
                                                          // Reply option
                                                          if (user != null)
                                                            ListTile(
                                                              leading:
                                                                  const Icon(
                                                                Icons.reply,
                                                                color:
                                                                    primaryBlue,
                                                              ),
                                                              title: const Text(
                                                                  'Reply'),
                                                              onTap: () {
                                                                setState(() {
                                                                  _replyingToId =
                                                                      message
                                                                          .id;
                                                                  _replyingToData =
                                                                      data;
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                            ),
                                                          // Report option
                                                          ListTile(
                                                            leading: const Icon(
                                                              Icons.flag,
                                                              color: Colors.red,
                                                            ),
                                                            title: const Text(
                                                                'Report'),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);
                                                              _reportMessage(
                                                                message.id,
                                                                data['author'] ??
                                                                    'Anonymous',
                                                              );
                                                            },
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.75,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isCurrentUser
                                                      ? const Color(0xFFDCF8C6)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            8),
                                                    topRight:
                                                        const Radius.circular(
                                                            8),
                                                    bottomLeft: Radius.circular(
                                                        isCurrentUser ? 8 : 0),
                                                    bottomRight:
                                                        Radius.circular(
                                                            isCurrentUser
                                                                ? 0
                                                                : 8),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 2,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (!isCurrentUser)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4),
                                                        child: Text(
                                                          data['author'] ??
                                                              'Anonymous',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: userColor,
                                                          ),
                                                        ),
                                                      ),
                                                    if (data['replyingToId'] !=
                                                        null)
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(bottom: 6),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isCurrentUser
                                                              ? Colors.green
                                                                  .shade100
                                                                  .withOpacity(
                                                                      0.4)
                                                              : Colors.grey
                                                                  .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border(
                                                            left: BorderSide(
                                                              color: isCurrentUser
                                                                  ? Colors.green
                                                                      .shade800
                                                                  : userColor,
                                                              width: 3,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              data['replyingToAuthor'] ??
                                                                  'Anonymous',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isCurrentUser
                                                                    ? Colors
                                                                        .green
                                                                        .shade900
                                                                    : userColor,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Text(
                                                              data['replyingToContent'] ??
                                                                  '',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    Text(
                                                      data['content'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          _formatTime(data[
                                                              'timestamp']),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isCurrentUser)
                                          const SizedBox(width: 8),
                                      ],
                                    ),
                                    if ((data['reactions'] as Map? ?? {})
                                        .isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 4,
                                          right: isCurrentUser ? 0 : 44,
                                          left: isCurrentUser ? 44 : 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: isCurrentUser
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 4,
                                              children:
                                                  (data['reactions'] as Map? ??
                                                          {})
                                                      .entries
                                                      .map((e) {
                                                final emoji = e.key;
                                                final userIds =
                                                    (e.value as List? ?? [])
                                                        .cast<String>();
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(emoji,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      14)),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${userIds.length}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Reply preview (if replying)
                    if (_replyingToId != null && _replyingToData != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryBlue, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Replying to ${_replyingToData?['author'] ?? 'Anonymous'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _replyingToData?['content'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: primaryBlue),
                              onPressed: () => setState(() {
                                _replyingToId = null;
                                _replyingToData = null;
                              }),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    // Emoji Picker
                    if (_showEmojiPicker)
                      Container(
                        height: 250,
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: GridView.count(
                          crossAxisCount: 8,
                          children: [
                            '😀',
                            '😃',
                            '😄',
                            '😁',
                            '😅',
                            '😂',
                            '🤣',
                            '😊',
                            '😇',
                            '🙂',
                            '🙃',
                            '😉',
                            '😌',
                            '😍',
                            '🥰',
                            '😘',
                            '😗',
                            '😙',
                            '😚',
                            '☺️',
                            '😋',
                            '😛',
                            '😝',
                            '😜',
                            '🤪',
                            '🤨',
                            '🧐',
                            '🤓',
                            '😎',
                            '🥸',
                            '🤩',
                            '🥳',
                            '😏',
                            '😒',
                            '😞',
                            '😔',
                            '😟',
                            '😕',
                            '🙁',
                            '☹️',
                            '😣',
                            '😖',
                            '😫',
                            '😩',
                            '🥺',
                            '😢',
                            '😭',
                            '😤',
                            '😠',
                            '😡',
                            '🤬',
                            '🤯',
                            '😳',
                            '🥵',
                            '🥶',
                            '😱',
                            '😨',
                            '😰',
                            '😥',
                            '😓',
                            '🤗',
                            '🤔',
                            '🤭',
                            '🤫',
                            '🤥',
                            '😶',
                            '😐',
                            '😑',
                            '😬',
                            '🙄',
                            '😯',
                            '😦',
                            '😧',
                            '😮',
                            '😲',
                            '🥱',
                            '😴',
                            '🤤',
                            '😪',
                            '😵',
                            '👍',
                            '👎',
                            '👏',
                            '🙌',
                            '👐',
                            '🤲',
                            '🤝',
                            '🙏',
                            '✌️',
                            '🤞',
                            '🤟',
                            '🤘',
                            '🤙',
                            '👌',
                            '🤏',
                            '👈',
                            '👉',
                            '👆',
                            '👇',
                            '☝️',
                            '✋',
                            '🤚',
                            '🖐',
                            '🖖',
                            '❤️',
                            '🧡',
                            '💛',
                            '💚',
                            '💙',
                            '💜',
                            '🖤',
                            '🤍',
                            '💔',
                            '❤️‍🔥',
                            '❤️‍🩹',
                            '💕',
                            '💞',
                            '💓',
                            '💗',
                            '💖',
                            '🔥',
                            '✨',
                            '💫',
                            '⭐',
                            '🌟',
                            '💥',
                            '💯',
                            '✅',
                          ]
                              .map((emoji) => GestureDetector(
                                    onTap: () {
                                      _messageController.text =
                                          _messageController.text + emoji;
                                      _messageController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                _messageController.text.length),
                                      );
                                    },
                                    child: Center(
                                      child: Text(emoji,
                                          style: const TextStyle(fontSize: 28)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    // Message input
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                });
                              },
                              icon: Icon(
                                _showEmojiPicker
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.newline,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _messageController.text.trim().isEmpty
                                  ? null
                                  : _sendMessage,
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _messageController.text.trim().isEmpty
                                      ? Colors.grey.shade300
                                      : emerald,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: _messageController.text.trim().isEmpty
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Join to chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join this community to participate',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _joinCommunity,
                          icon: const Icon(Icons.add),
                          label: const Text('Join Community'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'now';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}';
    } catch (e) {
      return 'now';
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'A';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final res = (first.toString() + second.toString()).trim();
    return res.isEmpty ? trimmed[0].toUpperCase() : res.toUpperCase();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// WhatsApp-style background painter with subtle pattern
class _ChatBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9D9D9).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw subtle doodle pattern
    const spacing = 60.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Draw small curved lines
        final path = Path();
        path.moveTo(x, y);
        path.quadraticBezierTo(x + 15, y + 10, x + 30, y);
        canvas.drawPath(path, paint);

        // Draw small circles
        canvas.drawCircle(Offset(x + 45, y + 20), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
