import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scholar Search App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _email = ''; // This will hold the email

  // Sample login logic to demonstrate navigation
  void _login() {
    setState(() {
      _email = _emailController.text;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScholarPage(userEmail: _email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter your email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Enter your password'),
              obscureText: true,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
                textStyle: TextStyle(color: Colors.white), // White text on button
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchScholarPage extends StatefulWidget {
  final String userEmail; // Add the userEmail field

  SearchScholarPage({required this.userEmail}); // Constructor to accept email

  @override
  _SearchScholarPageState createState() => _SearchScholarPageState();
}

class _SearchScholarPageState extends State<SearchScholarPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  String? _selectedScholar;
  String? _selectedScholarEmail;
  final String senderId = "123"; // Replace with dynamic sender ID if available
  final String senderEmail = "samaha@example.com"; // Replace with dynamic email if available

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/all_user'),
        headers: {'Content-Type': 'application/json'},
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

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) =>
          user['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToRequestPage() {
    if (_selectedScholar == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a scholar first!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestPage(
          senderId: senderId,
          senderEmail: senderEmail,
          receiverId: _selectedScholar!,
          receiverEmail: _selectedScholarEmail!,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search for Scholars',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: _filterUsers,
                      decoration: InputDecoration(
                        labelText: 'Enter Scholar Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    _isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.lightBlue))
                        : _filteredUsers.isEmpty
                        ? Center(child: Text('No data found'))
                        : SizedBox(
                      height: 200, // Fixed height for the list
                      child: _buildDropdownList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToRequestPage,
              child: Text('Request Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
                textStyle: TextStyle(color: Colors.white), // Set text color to white
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              _selectedScholar = user['id'];
              _selectedScholarEmail = user['email'];
              _searchController.text = user['email'] ?? '';
              _filteredUsers = [];
            });
          },
        );
      },
    );
  }
}

class RequestPage extends StatelessWidget {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String receiverEmail;

  RequestPage({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.receiverEmail,
  });

  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _submitRequest(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/scholar_request/insert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'description': _descriptionController.text,
          'sender_email': senderEmail,
          'receiver_email': receiverEmail,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestStatusPage(
              senderEmail: senderEmail,
              receiverEmail: receiverEmail,
              description: _descriptionController.text,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errors = errorData['errors'] ?? {};
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errors.values.join(', ')),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error submitting request: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Page'),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Why do you want to be friends?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _submitRequest(context),
                    child: Text('Send Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[400],
                      textStyle: TextStyle(color: Colors.white), // White text on button
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RequestStatusPage extends StatelessWidget {
  final String senderEmail;
  final String receiverEmail;
  final String description;

  RequestStatusPage({
    required this.senderEmail,
    required this.receiverEmail,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Status'),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Sender Email: $senderEmail'),
                SizedBox(height: 8),
                Text('Receiver Email: $receiverEmail'),
                SizedBox(height: 8),
                Text('Description: $description'),
                SizedBox(height: 8),
                Text(
                  'Status: Request Sent',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
