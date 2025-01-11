import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScholarPage extends StatefulWidget {
  @override
  _ScholarPageState createState() => _ScholarPageState();
}

class _ScholarPageState extends State<ScholarPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = []; // Holds the filtered users
  bool _isLoading = false;
  bool _hasMore = true;  // Flag to check if more data is available
  int _page = 1;  // Page number for pagination
  String _searchQuery = '';  // Store the search query

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch all users when the page loads
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> requestBody = {
        "search": _searchQuery,  // Search query is passed here to filter the results
        "page": _page,  // Pass page number for pagination
      };

      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/all_user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          setState(() {
            _hasMore = data['data'].length == 10;  // Check if there are more data
            _users.addAll(data['data']);  // Add new data to the existing list
            _filteredUsers = _users;  // Initially, show all users
          });
        } else {
          setState(() {
            _hasMore = false;  // No more data
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

  // Filter users based on the search query
  void _searchUsers() {
    setState(() {
      _filteredUsers = _users
          .where((user) => user['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Widget _buildTable() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No data found',  // Display a message if no users are available
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.lightBlue[300]),
        dataRowColor: MaterialStateProperty.all(Colors.lightBlue[100]),
        columnSpacing: 24.0,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
        dataTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        columns: const [
          DataColumn(label: Text('No.')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Degree')),
          DataColumn(label: Text('Shift')),
        ],
        rows: _filteredUsers.asMap().map((index, user) {
          return MapEntry(
            index,
            DataRow(cells: [
              DataCell(Text('${index + 1}')),  // Serial number, adjusted dynamically
              DataCell(Text(user['name'] ?? '')),  // User name
              DataCell(Text(user['email'] ?? '')),  // User email
              DataCell(Text(user['degree'] ?? '')),  // User degree
              DataCell(Text(user['shift'] ?? '')),  // User shift
            ]),
          );
        }).values.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scholars',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Container(
        color: Colors.white,  // White background for the body
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar and Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchQuery = value;  // Update search query
                      _searchUsers();  // Trigger search when the text changes
                    },
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.lightBlue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filteredUsers = _users;  // Reset filtered users
                    });
                    _searchUsers();  // Trigger search on button press
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[400],
                  ),
                  child: Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Data Table
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.lightBlue))
                  : _buildTable(),
            ),
            // Load more button
            if (_hasMore && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _page++;
                    });
                    _fetchUsers();  // Fetch more users when clicked
                  },
                  child: Text('Load More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
