import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_page.dart';
import 'update_attendance_page.dart';
import 'login_page.dart';
import 'prayeralarm.dart';
import 'location.dart';
import 'scholar.dart'; // Import ScholarPage
import 'search_scholar.dart'; // Import SearchScholarPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = 'User';
  String _email = '';
  String _phone = '';
  String _degree = '';
  String _shift = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'User';
      _email = prefs.getString('email') ?? '';
      _phone = prefs.getString('phone') ?? '';
      _degree = prefs.getString('degree') ?? '';
      _shift = prefs.getString('shift') ?? '';
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          name: _name,
          email: _email,
          phone: _phone,
          degree: _degree,
          shift: _shift,
        ),
      ),
    );
  }

  void _navigateToAttendancePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AttendancePage()),
    );
  }

  void _navigateToPrayerTimePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrayerTimePage(userId: _email)),
    );
  }

  void _navigateToScholarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScholarPage()),
    );
  }

  void _navigateToSearchScholarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScholarPage()),
    );
  }

  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool attendanceMarked = prefs.getBool('attendanceMarked') ?? false;
    bool pendingUpdate = prefs.getBool('pendingUpdate') ?? true;

    if (pendingUpdate) {
      _showDialog(
        title: 'Pending Update',
        message: 'Please resolve pending attendance updates before logging out.',
        onConfirm: () => _navigateToUpdateAttendance(),
      );
    } else if (!attendanceMarked) {
      _showDialog(
        title: 'Mark Attendance',
        message: 'You need to mark your attendance before logging out.',
        onConfirm: () => _navigateToUpdateAttendance(),
      );
    } else {
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }
  }

  void _navigateToUpdateAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UpdateAttendancePage(selectedDate: DateTime.now().toIso8601String()),
      ),
    );
  }

  void _navigateToLocationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPage()),
    );
  }

  void _showDialog(
      {required String title,
        required String message,
        required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_name!'),
        backgroundColor: Colors.lightBlue[400],
        actions: [
          PopupMenuButton<String>( // Profile and logout options
            onSelected: (value) {
              if (value == 'profile') {
                _navigateToProfile();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.lightBlue),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.lightBlue),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _navigateToSearchScholarPage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading for Modules
              Text(
                'My Modules',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue[400],
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildModuleButton(
                        'Mark Your Attendance',
                        Icons.check_circle,
                        Colors.lightBlue[400]!,
                        _navigateToAttendancePage,
                      ),
                      SizedBox(height: 16),
                      _buildModuleButton(
                        'Set Prayer Times',
                        Icons.access_alarm,
                        Colors.red[400]!,
                        _navigateToPrayerTimePage,
                      ),
                      SizedBox(height: 16),
                      _buildModuleButton(
                        'Your Favourite Location',
                        Icons.location_on,
                        Colors.green[400]!,
                        _navigateToLocationPage,
                      ),
                      SizedBox(height: 16),
                      _buildModuleButton(
                        'Scholars',
                        Icons.book,
                        Colors.purple[400]!,
                        _navigateToScholarPage,
                      ),
                      SizedBox(height: 16),
                      _buildModuleButton(
                        'Search Scholar',
                        Icons.search,
                        Colors.orange[400]!,
                        _navigateToSearchScholarPage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create buttons
  Widget _buildModuleButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String degree;
  final String shift;

  ProfilePage({
    required this.name,
    required this.email,
    required this.phone,
    required this.degree,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: Colors.lightBlue),
                  title: Text('Name',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(name),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.lightBlue),
                  title: Text('Email',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.lightBlue),
                  title: Text('Phone',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(phone),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.school, color: Colors.lightBlue),
                  title: Text('Degree',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(degree),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.access_time, color: Colors.lightBlue),
                  title: Text('Shift',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(shift),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
