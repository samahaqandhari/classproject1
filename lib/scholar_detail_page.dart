import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'scholar_requests_sent_page.dart'; // Import for navigation
import 'received_requests_page.dart'; // Import for navigation

class ScholarDetailPage extends StatefulWidget {
  @override
  _ScholarDetailPageState createState() => _ScholarDetailPageState();
}

class _ScholarDetailPageState extends State<ScholarDetailPage> {
  bool _isLoading = true;
  List<dynamic> _scholars = [];
  List<dynamic> _filteredScholars = [];
  String? _userId;
  Map<String, String> _requestStatus = {}; // Track request status

  @override
  void initState() {
    super.initState();
    _fetchScholarData();
  }

  Future<void> _fetchScholarData() async {
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

    setState(() {
      _userId = userId;
    });

    final url = Uri.parse('https://devtechtop.com/store/public/api/all_user');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _scholars = data['data'];
            _scholars.sort((a, b) => a['name'].compareTo(b['name'])); // Sort scholars by name
            _filteredScholars = _scholars;
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

  void _filterScholars(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredScholars = _scholars;
      } else {
        _filteredScholars = _scholars
            .where((scholar) =>
            scholar['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _sendRequest(String receiverId, String description) async {
    if (_userId == null) return;

    final url = Uri.parse('https://devtechtop.com/store/public/api/scholar_request/insert');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': _userId,
          'receiver_id': receiverId,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _requestStatus[receiverId] = 'pending';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to send request.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _showSendRequestDialog(String receiverId, String receiverName) {
    final TextEditingController _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.lightBlue[50],
        title: Text('Send Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To: $receiverName'),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _sendRequest(receiverId, _descriptionController.text);
              Navigator.pop(context);
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scholar Details'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.mail),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RequestsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.inbox),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AcceptedRequestsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterScholars,
              decoration: InputDecoration(
                labelText: 'Search Scholars',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _filteredScholars.isEmpty
                ? Center(child: Text('No scholars found.'))
                : ListView.builder(
              itemCount: _filteredScholars.length,
              itemBuilder: (context, index) {
                final scholar = _filteredScholars[index];
                final isRequestSent = _requestStatus[scholar['id']] == 'pending';
                return Card(
                  color: Colors.lightBlue[50],
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(scholar['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(scholar['email']),
                    trailing: isRequestSent
                        ? Text('Pending', style: TextStyle(color: Colors.orange))
                        : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _showSendRequestDialog(scholar['id'], scholar['name']);
                      },
                    ),
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
