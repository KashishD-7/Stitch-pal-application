import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'forgotpass.dart';
import 'register.dart';
import 'homev.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString("email_address") ?? prefs.getString("email");
    String? savedPassword = prefs.getString("password");
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
    if (savedPassword != null) {
      setState(() {
        _passwordController.text = savedPassword;
      });
    }
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://172.16.6.10:8000/api/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email_address": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['access'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_email', _emailController.text);

        // Save other user info if available
        if (data['user_id'] != null) await prefs.setString('user_id', data['user_id'].toString());
        if (data['full_name'] != null) await prefs.setString('full_name', data['full_name']);
        if (data['phone_number'] != null) await prefs.setString('phone_number', data['phone_number']);
        if (data['address'] != null) await prefs.setString('address', data['address']);
        if (data['shop_name'] != null) await prefs.setString('shop_name', data['shop_name']);
        if (data['user_type'] != null) await prefs.setString('user_type', data['user_type']);
        if (data['gender'] != null) await prefs.setString('gender', data['gender']);
        if (data['date_of_birth'] != null) await prefs.setString('date_of_birth', data['date_of_birth']);

        // 🚀 After successful login, navigate to Profile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateProfileScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid email or password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Login",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _buildTextField("Email", "Enter your email", false, _emailController),
                  _buildTextField("Password", "Enter your password", true, _passwordController),
                  SizedBox(height: 20),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () async {
                      await loginUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
                    },
                    child: Text("Forgot Password?",
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()));
                    },
                    child: Text("Register an Account ? ",
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),

                ],

              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, bool isPassword, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "$label is required";
            }
            if (label == "Email" && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return "Enter a valid email address";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
                : null,
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}