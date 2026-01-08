import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CounsellorsScreen extends StatefulWidget {
  const CounsellorsScreen({super.key});

  @override
  State<CounsellorsScreen> createState() => _CounsellorsScreenState();
}

class _CounsellorsScreenState extends State<CounsellorsScreen> {
  static const Color primaryPink = Color(0xFFFF6F91);
  static const Color emerald = Color(0xFF00D4A4);

  final List<Map<String, dynamic>> counsellors = [
    {
      'name': 'Dr. Sarah Anderson',
      'specialization': 'Addiction Psychology',
      'experience': '15 years',
      'rating': 4.9,
      'reviews': 127,
      'availability': 'Mon-Fri, 9 AM - 6 PM',
      'language': 'English, Spanish',
      'phone': '+1-555-0101',
      'email': 'sarah.anderson@counselling.com',
      'bio': 'Specialized in substance abuse recovery with evidence-based cognitive behavioral therapy.',
      'qualifications': 'PhD in Clinical Psychology, Licensed Therapist',
      'image': 'https://i.pravatar.cc/150?img=1',
      'color': const Color(0xFF4ECDC4),
    },
    {
      'name': 'Dr. Michael Chen',
      'specialization': 'Behavioral Therapy',
      'experience': '12 years',
      'rating': 4.8,
      'reviews': 98,
      'availability': 'Tue-Sat, 10 AM - 7 PM',
      'language': 'English, Mandarin',
      'phone': '+1-555-0102',
      'email': 'michael.chen@counselling.com',
      'bio': 'Expert in motivational interviewing and relapse prevention strategies.',
      'qualifications': 'MD, Certified Addiction Specialist',
      'image': 'https://i.pravatar.cc/150?img=12',
      'color': const Color(0xFF6BCF7F),
    },
    {
      'name': 'Dr. Emily Rodriguez',
      'specialization': 'Family Counseling',
      'experience': '10 years',
      'rating': 4.9,
      'reviews': 142,
      'availability': 'Mon-Thu, 8 AM - 5 PM',
      'language': 'English, Spanish, Portuguese',
      'phone': '+1-555-0103',
      'email': 'emily.rodriguez@counselling.com',
      'bio': 'Focuses on family dynamics and support systems in recovery journey.',
      'qualifications': 'MSW, Licensed Clinical Social Worker',
      'image': 'https://i.pravatar.cc/150?img=5',
      'color': const Color(0xFFAA96DA),
    },
    {
      'name': 'Dr. James Williams',
      'specialization': 'Trauma & PTSD',
      'experience': '18 years',
      'rating': 4.9,
      'reviews': 165,
      'availability': 'Mon-Fri, 11 AM - 8 PM',
      'language': 'English, French',
      'phone': '+1-555-0104',
      'email': 'james.williams@counselling.com',
      'bio': 'Specialized in treating co-occurring disorders and trauma-informed care.',
      'qualifications': 'PhD in Psychology, EMDR Certified',
      'image': 'https://i.pravatar.cc/150?img=13',
      'color': const Color(0xFF4D96FF),
    },
    {
      'name': 'Dr. Priya Sharma',
      'specialization': 'Holistic Recovery',
      'experience': '8 years',
      'rating': 4.7,
      'reviews': 81,
      'availability': 'Wed-Sun, 9 AM - 6 PM',
      'language': 'English, Hindi, Urdu',
      'phone': '+1-555-0105',
      'email': 'priya.sharma@counselling.com',
      'bio': 'Integrates mindfulness, yoga therapy, and traditional counseling methods.',
      'qualifications': 'MA Psychology, Certified Yoga Therapist',
      'image': 'https://i.pravatar.cc/150?img=9',
      'color': const Color(0xFFFFB347),
    },
    {
      'name': 'Dr. David Thompson',
      'specialization': 'Group Therapy',
      'experience': '14 years',
      'rating': 4.8,
      'reviews': 103,
      'availability': 'Mon-Sat, 10 AM - 7 PM',
      'language': 'English',
      'phone': '+1-555-0106',
      'email': 'david.thompson@counselling.com',
      'bio': 'Facilitates peer support groups and 12-step program integration.',
      'qualifications': 'PsyD, Certified Group Facilitator',
      'image': 'https://i.pravatar.cc/150?img=14',
      'color': const Color(0xFFFF6B6B),
    },
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        title: const Text(
          'Professional Counsellors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryPink.withValues(alpha: 0.9),
                  emerald.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.psychology, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Connect with Licensed Professionals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${counsellors.length} experienced counsellors available',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Counsellors list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: counsellors.length,
              itemBuilder: (context, index) {
                final counsellor = counsellors[index];
                return _buildCounsellorCard(context, counsellor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounsellorCard(BuildContext context, Map<String, dynamic> counsellor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (counsellor['color'] as Color).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCounsellorDetails(context, counsellor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: counsellor['color'],
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(counsellor['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            counsellor['name'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            counsellor['specialization'],
                            style: TextStyle(
                              fontSize: 14,
                              color: counsellor['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${counsellor['rating']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' (${counsellor['reviews']} reviews)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.work_outline,
                        counsellor['experience'],
                        counsellor['color'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.language,
                        counsellor['language'].split(',')[0],
                        counsellor['color'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(counsellor['phone']),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: counsellor['color'],
                          side: BorderSide(color: counsellor['color']),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCounsellorDetails(context, counsellor),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: counsellor['color'],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showCounsellorDetails(BuildContext context, Map<String, dynamic> counsellor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Profile section
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: counsellor['color'],
                            width: 4,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(counsellor['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      counsellor['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      counsellor['specialization'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: counsellor['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 20, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          '${counsellor['rating']} (${counsellor['reviews']} reviews)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bio
                    _buildDetailSection(
                      'About',
                      counsellor['bio'],
                      Icons.person_outline,
                      counsellor['color'],
                    ),
                    const SizedBox(height: 16),
                    // Qualifications
                    _buildDetailSection(
                      'Qualifications',
                      counsellor['qualifications'],
                      Icons.school_outlined,
                      counsellor['color'],
                    ),
                    const SizedBox(height: 16),
                    // Experience
                    _buildDetailSection(
                      'Experience',
                      counsellor['experience'],
                      Icons.work_outline,
                      counsellor['color'],
                    ),
                    const SizedBox(height: 16),
                    // Languages
                    _buildDetailSection(
                      'Languages',
                      counsellor['language'],
                      Icons.language,
                      counsellor['color'],
                    ),
                    const SizedBox(height: 16),
                    // Availability
                    _buildDetailSection(
                      'Availability',
                      counsellor['availability'],
                      Icons.calendar_today,
                      counsellor['color'],
                    ),
                    const SizedBox(height: 24),
                    // Contact buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendEmail(counsellor['email']),
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: counsellor['color'],
                              side: BorderSide(color: counsellor['color'], width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(counsellor['phone']),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: counsellor['color'],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _copyContact(context, counsellor),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Contact Info'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildDetailSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Counsellors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Counsellors'),
              leading: Radio(
                value: 'All',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() => _selectedFilter = value.toString());
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Addiction Psychology'),
              leading: Radio(
                value: 'Addiction Psychology',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() => _selectedFilter = value.toString());
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Family Counseling'),
              leading: Radio(
                value: 'Family Counseling',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() => _selectedFilter = value.toString());
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Counselling Inquiry',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  void _copyContact(BuildContext context, Map<String, dynamic> counsellor) {
    final contactInfo = '''
${counsellor['name']}
${counsellor['specialization']}
Phone: ${counsellor['phone']}
Email: ${counsellor['email']}
Availability: ${counsellor['availability']}
    ''';
    
    Clipboard.setData(ClipboardData(text: contactInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact info copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
