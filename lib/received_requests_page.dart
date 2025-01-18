import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivedRequestsPage extends StatefulWidget {
  @override
  _ReceivedRequestsPageState createState() => _ReceivedRequestsPageState();
}

class _ReceivedRequestsPageState extends State<ReceivedRequestsPage> {
  bool _isLoading = true;
  List<dynamic> _receivedRequests = [];
  String? _userName; // To store your logged-in user name

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchReceivedRequests();
  }

  Future<void> _loadUserData() async {
    // Load user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name');
    });
  }

  Future<void> _fetchReceivedRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      return;
    }

    final url = Uri.parse('https://devtechtop.com/store/public/api/scholar_request/all');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      print('Request sent with user_id: $userId');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _receivedRequests = data['data'];
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to load data.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Received Requests'),
        backgroundColor: Colors.lightBlueAccent, // Sky Blue
      ),
      body: Column(
        children: [
          // Display the logged-in user's name
          if (_userName != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Logged in as: $_userName',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _receivedRequests.isEmpty
                ? Center(child: Text('No requests found.'))
                : ListView.builder(
              itemCount: _receivedRequests.length,
              itemBuilder: (context, index) {
                final request = _receivedRequests[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  elevation: 5,
                  child: ListTile(
                    title: Text(request['reciever_name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${request['description']}'),
                        Text('Sent at: ${request['created_at']}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
