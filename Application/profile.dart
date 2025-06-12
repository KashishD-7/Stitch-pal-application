import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home.dart';
import 'homev.dart'; // Import vendor home page
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // For mobile platforms
  File? _imageFile;

  // For web platforms
  Uint8List? _webImage;
  String? _webImageName;

  final ImagePicker _picker = ImagePicker();
  String _userType = "Tailor"; // Default value

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _nameController.text = prefs.getString('full_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? prefs.getString('email_address') ?? '';
      _phoneController.text = prefs.getString('phone_number') ?? '';
      _addressController.text = prefs.getString('address') ?? '';
      if (prefs.containsKey('shop_name')) {
        _shopNameController.text = prefs.getString('shop_name')!;
      } else {
        _shopNameController.clear();
      }
      _passwordController.text = prefs.getString('password') ?? '';
      _confirmPasswordController.text = prefs.getString('password') ?? '';
      _userType = prefs.getString('user_type') ?? 'Tailor';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web
        _webImage = await pickedFile.readAsBytes();
        _webImageName = pickedFile.name;
        setState(() {});
      } else {
        // For mobile
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location services are disabled.")));
      return;
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permissions are permanently denied.")));
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _addressController.text = "Lat: ${position.latitude}, Long: ${position.longitude}";
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location Updated")));
  }

  Future<void> _saveProfileAndRedirect() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      print(token);
      String apiUrl = "http://172.16.6.10:8000/api/update-profile/";

      if (!kIsWeb && _imageFile == null && _webImage == null) {
        // Just update shop name if no image selected
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'shop_name': _shopNameController.text,
          }),
        );

        if (response.statusCode == 200) {
          await prefs.setString('shop_name', _shopNameController.text);
          _handleSuccessAndNavigate(prefs);
        } else {
          _showErrorMessage('Failed to update profile. Error: ${response.statusCode}');
        }
        return;
      }

      // Handle multipart request based on platform
      if (kIsWeb) {
        // For web, use base64 encoding for the image
        if (_webImage != null) {
          final base64Image = base64Encode(_webImage!);
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_name': _shopNameController.text,
              'image': base64Image,
              'image_name': _webImageName ?? 'web_image.jpg',
            }),
          );

          if (response.statusCode == 200) {
            await prefs.setString('shop_name', _shopNameController.text);
            _handleSuccessAndNavigate(prefs);
          } else {
            _showErrorMessage('Failed to update profile. Error: ${response.statusCode}');
          }
        } else {
          _showErrorMessage('No image selected.');
        }
      } else {
        // For mobile platforms
        var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['shop_name'] = _shopNameController.text;

        if (_imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              _imageFile!.path,
              filename: path.basename(_imageFile!.path),
            ),
          );
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          await prefs.setString('shop_name', _shopNameController.text);
          _handleSuccessAndNavigate(prefs);
        } else {
          _showErrorMessage('Failed to update profile. Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    }
  }

  void _handleSuccessAndNavigate(SharedPreferences prefs) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile updated successfully")),
    );

    // Navigate to appropriate home page
    String userType = prefs.getString('user_type') ?? 'Tailor';
    if (userType == "Vendor") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen1()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Create Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: !kIsWeb && _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_webImage != null
                            ? MemoryImage(_webImage!) as ImageProvider
                            : null),
                        child: (_imageFile == null && _webImage == null)
                            ? Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.black),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _buildTextField("Shop Name", "Enter your shop name", _shopNameController),
                _buildTextField("Full Name", "Enter your full name", _nameController),
                _buildTextField("Email Address", "Enter your email", _emailController),
                _buildTextField("Phone Number", "Enter your phone number", _phoneController),
                _buildAddressField(), // Updated address field with live location button inside
                _buildPasswordField("Set Password", "Enter password", _passwordController, true),
                _buildPasswordField("Confirm Password", "Re-enter password", _confirmPasswordController, false),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfileAndRedirect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text("Create Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: (value) => value!.isEmpty ? "$label is required" : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          maxLines: maxLines,
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildPasswordField(String label, String hint, TextEditingController controller, bool isPasswordField) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isPasswordField ? !_isPasswordVisible : !_isConfirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) return "$label is required";
            if (label == "Set Password" && value.length < 6) return "Password must be at least 6 characters";
            if (label == "Confirm Password" && value != _passwordController.text) return "Passwords do not match";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
            suffixIcon: IconButton(
              icon: Icon(isPasswordField
                  ? (_isPasswordVisible ? Icons.visibility : Icons.visibility_off)
                  : (_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off)),
              onPressed: () {
                setState(() {
                  if (isPasswordField) {
                    _isPasswordVisible = !_isPasswordVisible;
                  } else {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  }
                });
              },
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Shop Address", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextFormField(
          controller: _addressController,
          validator: (value) => value!.isEmpty ? "Shop Address is required" : null,
          decoration: InputDecoration(
            hintText: "Enter your shop address",
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
            suffixIcon: IconButton(
              icon: Icon(Icons.my_location, color: Colors.blue),
              onPressed: _getCurrentLocation,
            ),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 15),
      ],
    );
  }
}