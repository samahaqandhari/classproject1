import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedDegree;
  String? _selectedShift;
  bool _isLaravelDeveloper = false;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String? _cellNo;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveUserData(String name, String email, String phone, String degree, String shift) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
    await prefs.setString('degree', degree);
    await prefs.setString('shift', shift);
  }

  Future<void> _submitToAPI({
    required String name,
    required String email,
    required String password,
    required String cellNo,
    required String shift,
    required String degree,
  }) async {
    const String apiUrl = 'https://devtechtop.com/classproject/public/insert_user';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'cell_no': cellNo,
          'shift': shift,
          'degree': degree,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Register Successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup successful!')),
          );
          Navigator.pushNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message']}')),
          );
        }
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email already exists. Please use a different email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.lightBlue[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Create a New Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your name';
                  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) return 'Name can only contain letters and spaces';
                  return null;
                },
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w-.]+@[\w-]+\.[a-zA-Z]+$').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.lightBlue[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              SizedBox(height: 10),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.lightBlue[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.lightBlue[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your phone number';
                  if (value.length != 11) return 'Phone number must be exactly 11 digits';
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _cellNo = value;
                  });
                },
              ),
              SizedBox(height: 10),
              _buildDropdownField(
                label: 'Degree',
                items: ['BS IT', 'BS CS', 'BS Psychology'],
                validator: (value) => value == null ? 'Please select your degree' : null,
                onChanged: (value) {
                  setState(() {
                    _selectedDegree = value;
                  });
                },
              ),
              SizedBox(height: 10),
              _buildDropdownField(
                label: 'Shift',
                items: ['Morning', 'Evening'],
                validator: (value) => value == null ? 'Please select a shift' : null,
                onChanged: (value) {
                  setState(() {
                    _selectedShift = value;
                  });
                },
              ),
              SizedBox(height: 10),
              Text(
                'Are you a Laravel developer?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue[400],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue[400],
                        ),
                      ),
                      value: _isLaravelDeveloper,
                      onChanged: (value) {
                        setState(() {
                          _isLaravelDeveloper = value!;
                        });
                      },
                      activeColor: Colors.lightBlue[400],
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        'No',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue[400],
                        ),
                      ),
                      value: !_isLaravelDeveloper,
                      onChanged: (value) {
                        setState(() {
                          _isLaravelDeveloper = !value!;
                        });
                      },
                      activeColor: Colors.lightBlue[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildButton('Signup', () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _isSubmitting = true;
                  });

                  await Future.delayed(Duration(seconds: 1));

                  String name = _nameController.text.trim();
                  String email = _emailController.text.trim();
                  String password = _passwordController.text.trim();
                  String cellNo = _cellNo ?? '';
                  String degree = _selectedDegree ?? '';
                  String shift = _selectedShift ?? '';

                  _saveUserData(name, email, cellNo, degree, shift);

                  await _submitToAPI(
                    name: name,
                    email: email,
                    password: password,
                    cellNo: cellNo,
                    shift: shift,
                    degree: degree,
                  );

                  setState(() {
                    _isSubmitting = false;
                  });
                }
              }),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text('Already have an account? Login',
                    style: TextStyle(color: Colors.lightBlue[400])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.lightBlue[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.school, color: Colors.lightBlue[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildButton(String label, void Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50), backgroundColor: Colors.lightBlue[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text(label, style: TextStyle(fontSize: 18)),
    );
  }
}
