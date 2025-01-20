import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class AcceptedRequestsScreen extends StatefulWidget {
  @override
  _AcceptedRequestsScreenState createState() => _AcceptedRequestsScreenState();
}

class _AcceptedRequestsScreenState extends State<AcceptedRequestsScreen> {
  List<dynamic> acceptedRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('id') ?? '';
    });
    if (userId.isNotEmpty) {
      fetchAcceptedRequests();
    } else {
      setState(() {
        errorMessage = 'User ID not found. Please log in again.';
        isLoading = false;
      });
    }
  }

  Future<void> fetchAcceptedRequests() async {
    final String apiUrl = 'https://devtechtop.com/store/public/api/accepted/scholar_request';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          setState(() {
            acceptedRequests = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Unexpected response format.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load accepted requests. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Requests'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
          : acceptedRequests.isEmpty
          ? const Center(child: Text('No accepted requests found.'))
          : ListView.builder(
        itemCount: acceptedRequests.length,
        itemBuilder: (context, index) {
          final request = acceptedRequests[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(request['sender_name'] ?? 'Unknown'),
              subtitle: Text('Status: ${request['status'] ?? 'N/A'}'),
              trailing: IconButton(
                icon: const Icon(Icons.chat, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderName: request['sender_name'] ?? 'Unknown',
                        senderId: request['sender_id'] ?? '',
                        receiverName: request['receiver_name'] ?? 'Unknown',
                        receiverId: request['receiver_id'] ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
