import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'update_attendance_page.dart';

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<String> _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, bool> _attendanceStatus = {};
  late String _currentDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Set the initial selected date to today
    _currentDate = _formatDate(_selectedDate);
    _initializeAttendance();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _initializeAttendance() async {
    // Fetch attendance records for the selected date
    List<Map<String, dynamic>> attendanceRecords = await _dbHelper.getAttendanceByDate(_currentDate);
    setState(() {
      _attendanceStatus = {
        for (var prayer in _prayers)
          prayer: attendanceRecords.any((record) => record['prayer'] == prayer),
      };
    });
  }

  Future<void> _markAttendance(String prayer) async {
    String timestamp = DateTime.now().toIso8601String();
    await _dbHelper.insertAttendance(prayer, timestamp, _currentDate);
    setState(() {
      _attendanceStatus[prayer] = true;
    });

    // Send updated attendance status to API
    _sendAttendanceToApi(
      userId: '123', // Replace with actual user ID
      date: _currentDate,
      attendanceStatus: _attendanceStatus,
    );
  }

  Future<void> _sendAttendanceToApi({
    required String userId,
    required String date,
    required Map<String, bool> attendanceStatus,
  }) async {
    const String apiUrl = 'https://devtechtop.com/store/public/insert_prayer';
    Map<String, String> headers = {'Content-Type': 'application/json'};

    Map<String, dynamic> body = {
      'user_id': userId,
      'date': date,
      'fajar': attendanceStatus['Fajr'] == true ? 1 : 0,
      'zuhar': attendanceStatus['Dhuhr'] == true ? 1 : 0,
      'asar': attendanceStatus['Asr'] == true ? 1 : 0,
      'mugrab': attendanceStatus['Maghrib'] == true ? 1 : 0,
      'isha': attendanceStatus['Isha'] == true ? 1 : 0,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attendance successfully submitted!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['errors']}')),
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

  bool _isPastDate(DateTime date) {
    return date.isBefore(DateTime.now()) || date.isAtSameMomentAs(DateTime.now());
  }

  // Check if all prayers are marked for the selected date
  bool _isAllPrayersMarked() {
    return _attendanceStatus.values.every((isMarked) => isMarked);
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
              },
              child: Text('Yes'),
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
        title: Text('Mark Prayer Attendance'),
        backgroundColor: Colors.lightBlue[400],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Calendar for selecting the date
            TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime(2020),
              lastDay: DateTime.now(), // Ensure future dates are disabled
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                if (_isPastDate(selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _currentDate = _formatDate(selectedDay);
                    _initializeAttendance();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You cannot mark attendance for future dates.')));
                }
              },
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, date, _) {
                  bool allPrayersMarked = _isAllPrayersMarked();
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: allPrayersMarked ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Attendance for $_currentDate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _prayers.length,
                itemBuilder: (context, index) {
                  String prayer = _prayers[index];
                  bool isMarked = _attendanceStatus[prayer] ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      title: Text(
                        prayer,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          if (!isMarked) {
                            _markAttendance(prayer);
                          }
                        },
                        child: Icon(
                          isMarked ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isMarked ? Colors.green : Colors.lightBlue[300],
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Update Attendance'),
        icon: Icon(Icons.update),
        backgroundColor: Colors.lightBlue[400],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UpdateAttendancePage(selectedDate: _currentDate)),
          );
        },
      ),
    );
  }
}  