import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../home/homescreen.dart';
import '../forum/community_forum_screen.dart';
import '../report/report_case_screen.dart';
import '../profile/profile_screen.dart';

class RehabCentersScreen extends StatefulWidget {
  const RehabCentersScreen({super.key});

  @override
  State<RehabCentersScreen> createState() => _RehabCentersScreenState();
}

class _RehabCentersScreenState extends State<RehabCentersScreen> {
  int _currentNavIndex = 0;
  bool _isLoading = false;
  Position? _currentPosition;
  bool _hasDetected = false;

  // College of Engineering Kallooppara reference location for distance labels
  static const double _referenceLat = 9.3873;
  static const double _referenceLng = 76.6413;

  // Pathanamthitta-area rehab centers (mock data; normally from API)
  final List<Map<String, dynamic>> _centers = [
    {
      'name': 'Manna Rehabilitation & Wellness',
      'address': 'KP Road, Pathanamthitta',
      'lat': 9.2669,
      'lng': 76.7870,
      'phone': '+91 97456 12345',
      'type': 'Inpatient & Counseling',
      'hours': 'Open 24/7',
      'color': const Color(0xFF4ECDC4),
    },
    {
      'name': 'Santhwana Recovery Home',
      'address': 'Thiruvalla - Pathanamthitta Rd, Adoor',
      'lat': 9.1526,
      'lng': 76.7307,
      'phone': '+91 90721 44550',
      'type': 'Detox & Therapy',
      'hours': '6 AM - 11 PM',
      'color': const Color(0xFFFF6B6B),
    },
    {
      'name': 'Snehatheeram De-Addiction Center',
      'address': 'Mylapra, Pathanamthitta',
      'lat': 9.3073,
      'lng': 76.8017,
      'phone': '+91 98470 22880',
      'type': 'Inpatient & Aftercare',
      'hours': '8 AM - 10 PM',
      'color': const Color(0xFF9B59B6),
    },
    {
      'name': 'Anugraha Care & Rehab',
      'address': 'Ranni-Perunad Rd, Ranni',
      'lat': 9.3977,
      'lng': 76.8199,
      'phone': '+91 96330 55441',
      'type': 'Residential & Counseling',
      'hours': 'Open 24/7',
      'color': const Color(0xFF3498DB),
    },
    {
      'name': 'Punarjani Wellness Clinic',
      'address': 'Thiruvalla-Pandalam Rd, Thiruvalla',
      'lat': 9.3813,
      'lng': 76.5740,
      'phone': '+91 80890 66778',
      'type': 'Therapy & Outpatient',
      'hours': '7 AM - 9 PM',
      'color': const Color(0xFFF4B400),
    },
  ];

  Future<void> _detectNearby() async {
    setState(() => _isLoading = true);

    try {
      final permission = await Permission.location.request();
      if (permission.isDenied) {
        _showPermissionDialog(
          'Location Permission Required',
          'Allow location to find rehab centers near you.',
        );
        setState(() => _isLoading = false);
        return;
      }
      if (permission.isPermanentlyDenied) {
        _showPermissionDialog(
          'Location Permanently Denied',
          'Please enable location permission in app settings.',
        );
        setState(() => _isLoading = false);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services');
        setState(() => _isLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _currentPosition = pos;
        _hasDetected = true;
      });
    } catch (e) {
      _showSnackBar('Unable to get location. Please try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _distanceToCenter(Map<String, dynamic> center) {
    return Geolocator.distanceBetween(
      _referenceLat,
      _referenceLng,
      center['lat'],
      center['lng'],
    );
  }

  List<Map<String, dynamic>> get _sortedCenters {
    if (!_hasDetected) return [];
    final list = [..._centers];
    list.sort((a, b) {
      final da = _distanceToCenter(a);
      final db = _distanceToCenter(b);
      return da.compareTo(db);
    });
    return list;
  }

  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
            ),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4ECDC4),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _distanceLabel(Map<String, dynamic> center) {
    final d = _distanceToCenter(center);
    if (d >= 1000) {
      return '${(d / 1000).toStringAsFixed(1)} km from here';
    }
    return '${d.toStringAsFixed(0)} m from here';
  }

  @override
  Widget build(BuildContext context) {
    final centers = _sortedCenters;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        title: const Text('Rehab Centers',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.local_hospital,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Rehab Centers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Locate nearby centers for support and recovery',
                            style: TextStyle(
                              color: Colors.white70,
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

              // Detect button
              Container(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.my_location,
                              color: Color(0xFF4ECDC4)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Detect rehab centers near your location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _detectNearby,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Detecting...' : 'Detect Nearby Centers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Nearby Rehab Centers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              if (!_hasDetected) ...[
                Container(
                  width: double.infinity,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_searching,
                            color: Color(0xFF4ECDC4)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tap "Detect Nearby Centers" to load centers around you.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Centers list
              ...centers.map((center) {
                final color = center['color'] as Color;
                final distanceLabel = _distanceLabel(center);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    Icon(Icons.health_and_safety, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      center['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      center['address'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  distanceLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoChip(Icons.access_time, center['hours'],
                                  Colors.blueGrey),
                              const SizedBox(width: 8),
                              _infoChip(Icons.medical_information,
                                  center['type'], color),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.call,
                                  color: Colors.grey[600], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                center['phone'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
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
}
