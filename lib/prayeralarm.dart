import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class PrayerTimePage extends StatefulWidget {
  final String userId; // Add userId as a parameter

  PrayerTimePage({required this.userId}); // Initialize with user ID

  @override
  _PrayerTimePageState createState() => _PrayerTimePageState();
}

class _PrayerTimePageState extends State<PrayerTimePage> {
  final List<String> _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, TimeOfDay?> _prayerTimes = {};
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeTimezones();
    _requestNotificationPermission();
    _loadPrayerTimes();
  }

  // Initialize timezones
  void _initializeTimezones() {
    tz.initializeTimeZones();
  }

  // Request Notification Permissions
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Load saved prayer times from local storage for the current user
  Future<void> _loadPrayerTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _prayerTimes = {
        for (var prayer in _prayers)
          prayer: prefs.containsKey('${widget.userId}_$prayer')
              ? _parseTime(prefs.getString('${widget.userId}_$prayer')!)
              : null,
      };
    });
  }

  // Save a prayer time to local storage for the current user
  Future<void> _savePrayerTime(String prayer, TimeOfDay time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widget.userId}_$prayer', _formatTime(time));
    setState(() {
      _prayerTimes[prayer] = time;
    });
    _scheduleNotification(prayer, time);
  }

  // Schedule a notification for a specific prayer time
  Future<void> _scheduleNotification(String prayer, TimeOfDay time) async {
    final now = DateTime.now();
    final notificationTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Check if the time is in the past; if so, schedule for the next day
    final scheduleTime = notificationTime.isBefore(now)
        ? notificationTime.add(Duration(days: 1))
        : notificationTime;

    await _notificationsPlugin.zonedSchedule(
      prayer.hashCode,
      'Prayer Reminder',
      'It\'s time for $prayer prayer.',
      tz.TZDateTime.from(scheduleTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel_id',
          'Prayer Notifications',
          channelDescription: 'Channel for prayer reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Format a TimeOfDay as HH:mm:ss
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final formatted =
    DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hms().format(formatted);
  }

  // Parse a HH:mm:ss string into a TimeOfDay
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return TimeOfDay(hour: parts[0], minute: parts[1]);
  }

  // Show a time picker and save the selected time
  Future<void> _pickTime(BuildContext context, String prayer) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: _prayerTimes[prayer] ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      _savePrayerTime(prayer, selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set Prayer Times',
          style: TextStyle(color: Colors.white), // Change title text color to white
        ),
        backgroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Change icon color to white
      ),
      body: ListView.builder(
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          String prayer = _prayers[index];
          TimeOfDay? time = _prayerTimes[prayer];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                prayer,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                time != null
                    ? 'Time: ${_formatTime(time)}'
                    : 'Tap to set time',
                style: TextStyle(
                  fontSize: 16,
                  color: time != null ? Colors.green : Colors.red,
                ),
              ),
              trailing: Icon(Icons.timer, color: Colors.black),
              onTap: () => _pickTime(context, prayer),
            ),
          );
        },
      ),
    );
  }
}
