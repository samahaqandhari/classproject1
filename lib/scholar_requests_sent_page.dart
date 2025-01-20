import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  String _userId = '';
  late TabController _tabController;

  List<dynamic> _sentRequests = [];
  List<dynamic> _receivedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('id') ?? '';
    });
    if (_userId.isNotEmpty) {
      _fetchRequests();
    } else {
      setState(() {
        _errorMessage = 'User ID not found. Please log in again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRequests() async {
    final url = Uri.parse('https://devtechtop.com/store/public/api/scholar_request/all');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': _userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          setState(() {
            _sentRequests = data['data']
                .where((request) => request['sender_id']?.toString() == _userId)
                .toList();
            _receivedRequests = data['data']
                .where((request) => request['receiver_id']?.toString() == _userId)
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load requests. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final url = Uri.parse('https://devtechtop.com/store/public/api/cancel/scholar_request');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'request_id': requestId}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          // Remove the canceled request from the list
          _sentRequests.removeWhere((request) => request['id'] == requestId);
          _receivedRequests.removeWhere((request) => request['id'] == requestId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request canceled successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to cancel request.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final url = Uri.parse('https://devtechtop.com/store/public/api/update/scholar_request');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'request_id': requestId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 'error') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['request_id'] ?? 'Request ID is required.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request accepted successfully.')),
          );
          // Optionally, you can update the request status or remove it from the list.
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept the request. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sender: ${request['sender_name'] ?? 'Unknown'}'),
              Text('Receiver: ${request['reciever_name'] ?? 'Unknown'}'),
              Text('Status: ${request['status'] ?? 'N/A'}'),
              Text('Description: ${request['description'] ?? 'No description'}'),
              Text('Entry Date & Time: ${request['entry_date_time'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelRequest(request['id']); // Call cancel request API here
              },
              child: const Text('Cancel Request'),
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
        title: const Text('My Requests'),
        backgroundColor: Colors.lightBlueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Sent Requests'),
            Tab(icon: Icon(Icons.inbox), text: 'Received Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          // Sent Requests Tab
          Column(
            children: [
              Expanded(
                child: _sentRequests.isEmpty
                    ? const Center(child: Text('No sent requests found.'))
                    : ListView.builder(
                  itemCount: _sentRequests.length,
                  itemBuilder: (context, index) {
                    final request = _sentRequests[index];
                    return Card(
                      color: Colors.lightBlue.shade100,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.send,
                          color: Colors.blue,
                        ),
                        title: Text(request['reciever_name'] ?? 'Unknown'),
                        subtitle: Text('Status: ${request['status'] ?? 'N/A'}'),
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            _showRequestDetails(request);
                          },
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Received Requests Tab
          Column(
            children: [
              Expanded(
                child: _receivedRequests.isEmpty
                    ? const Center(child: Text('No received requests found.'))
                    : ListView.builder(
                  itemCount: _receivedRequests.length,
                  itemBuilder: (context, index) {
                    final request = _receivedRequests[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.inbox,
                          color: Colors.green,
                        ),
                        title: Text(request['sender_name'] ?? 'Unknown'),
                        subtitle: Text('Status: ${request['status'] ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                _acceptRequest(request['id']); // Call the accept request API here
                              },
                              child: const Text('Accept', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                _showRequestDetails(request);
                              },
                              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
