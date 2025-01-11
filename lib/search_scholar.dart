import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScholarPage extends StatefulWidget {
  @override
  _SearchScholarPageState createState() => _SearchScholarPageState();
}

class _SearchScholarPageState extends State<SearchScholarPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  String? _selectedScholar; // Store the selected scholar

  // Fetch all users from the API
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/all_user'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          setState(() {
            _users = data['data'] ?? [];
          });
        } else {
          setState(() {
            _users = [];
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter the users based on the search input
  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) =>
          user['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Send a request to the selected scholar
  Future<void> _sendRequest() async {
    if (_selectedScholar == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a scholar first!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Here, you can add the logic to send the request to the scholar
    // For now, we'll show a success message after a mock request is sent.
    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/send_request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'scholar_id': _selectedScholar, // Example body data
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request sent to scholar successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        throw Exception('Failed to send request');
      }
    } catch (e) {
      print('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send request. Please try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Scholar'),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Search for Scholars',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filterUsers, // Trigger search filter on input change
              decoration: InputDecoration(
                labelText: 'Enter Scholar Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator(color: Colors.lightBlue)
                : _filteredUsers.isEmpty
                ? Text('No data found')
                : Expanded(
              child: _buildDropdownList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendRequest, // Send request on button press
              child: Text('Request Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a Dropdown with filtered users based on search input
  Widget _buildDropdownList() {
    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return ListTile(
          title: Text(user['name'] ?? ''),
          subtitle: Text(
              'Email: ${user['email'] ?? ''} | Degree: ${user['degree'] ?? ''} | Shift: ${user['shift'] ?? ''}'),
          onTap: () {
            setState(() {
              _selectedScholar = user['id']; // Store selected scholar's id
              _searchController.text = user['name'] ?? ''; // Update search bar with selected name
              _filteredUsers = []; // Hide the dropdown list after selection
            });
          },
        );
      },
    );
  }
}
