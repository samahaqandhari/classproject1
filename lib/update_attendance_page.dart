import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'login_page.dart';

class UpdateAttendancePage extends StatefulWidget {
  final String selectedDate;

  // Constructor to accept the selected date
  UpdateAttendancePage({required this.selectedDate});

  @override
  _UpdateAttendancePageState createState() => _UpdateAttendancePageState();
}

class _UpdateAttendancePageState extends State<UpdateAttendancePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _markedPrayers = [];

  @override
  void initState() {
    super.initState();
    _loadMarkedPrayers();
  }

  // Load the marked prayers for the selected date
  Future<void> _loadMarkedPrayers() async {
    List<Map<String, dynamic>> prayers = await _dbHelper.getAttendanceByDate(widget.selectedDate);
    setState(() {
      _markedPrayers = prayers;
    });
  }

  // Method to send updated attendance to the API
  Future<void> _sendAttendanceToApi({
    required String userId,
    required String date,
    required List<Map<String, dynamic>> prayers,
  }) async {
    const String apiUrl = 'https://devtechtop.com/store/public/select_prayer';
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Prepare the data for the API
    Map<String, dynamic> body = {
      'user_id': userId,
      'date': date,
      'fajr': prayers.any((prayer) => prayer['prayer'] == 'Fajr') ? 1 : 0,
      'zuhr': prayers.any((prayer) => prayer['prayer'] == 'Dhuhr') ? 1 : 0,
      'asar': prayers.any((prayer) => prayer['prayer'] == 'Asr') ? 1 : 0,
      'mugrab': prayers.any((prayer) => prayer['prayer'] == 'Maghrib') ? 1 : 0,
      'isha': prayers.any((prayer) => prayer['prayer'] == 'Isha') ? 1 : 0,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attendance successfully submitted!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['error']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit attendance: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // Method to update attendance and redirect to login
  Future<void> _updateAttendance() async {
    if (_markedPrayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No prayers marked for attendance!')),
      );
      return;
    }

    // Get the user ID from SharedPreferences (or other logic to fetch it)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('user_id') ?? '0'; // Replace '0' with default user ID if necessary

    // Send updated attendance to API
    await _sendAttendanceToApi(
      userId: userId,
      date: widget.selectedDate,
      prayers: _markedPrayers,
    );

    // Update attendance in the database
    for (var prayer in _markedPrayers) {
      final String date = widget.selectedDate; // Use the selected date
      final String time = DateTime.now().toIso8601String();

      // Update the attendance data in the database
      await _dbHelper.updateAttendance(
        prayer['prayer'],             // Prayer name
        date,                         // Date
        time,                         // Current time
        prayer['user_id'],            // User ID
      );
    }

    // Mark attendance as updated in SharedPreferences
    await prefs.setBool('attendanceMarked', true);
    await prefs.setBool('pendingUpdate', false);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance updated successfully!')),
    );
  }

  // Method to logout the user and navigate to LoginPage
  Future<void> _logout() async {
    // Clear SQLite data
    await _dbHelper.clearDatabase();

    // Clear SharedPreferences to logout user
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to LoginPage after logout
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Attendance'),
        backgroundColor: Colors.lightBlue[400],  // Sky blue color for app bar
      ),
      body: _markedPrayers.isEmpty
          ? Center(
        child: Text(
          'No marked prayers found for ${widget.selectedDate}.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      )
          : ListView.builder(
        itemCount: _markedPrayers.length,
        itemBuilder: (context, index) {
          final prayer = _markedPrayers[index];
          final DateTime timestamp = DateTime.parse(prayer['timestamp']);
          final String date = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          final String time = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlue[400]),
                  ),
                  SizedBox(height: 8),
                  Text('Prayer: ${prayer['prayer']}', style: TextStyle(fontSize: 14)),
                  Text('Time: $time', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updateAttendance,
        label: Text('Update Attendance'),
        icon: Icon(Icons.update),
        backgroundColor: Colors.lightBlue[400],  // Sky blue for FAB
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400], // Sky blue for button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Logout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}