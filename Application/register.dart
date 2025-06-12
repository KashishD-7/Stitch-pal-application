import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 't&c.dart';
import 'db_helper.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isAddressExpanded = false;
  bool _agreeToTerms = false;
  String _gender = "Male";
  String _userType = "Tailor";

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _addressController.text = "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      final userData = {
        "full_name": _nameController.text,
        "email_address": _emailController.text,
        "password": _passwordController.text,
        "phone_number": _phoneController.text,
        "date_of_birth": _dobController.text,
        "gender": _gender,
        "user_type": _userType,
        "shop_name": "",
        "address": _addressController.text,
        "pincode": _pincodeController.text,
        "address_line_1": _addressLine1Controller.text,
        "address_line_2": _addressLine2Controller.text,
        "landmark": _landmarkController.text,
      };

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match")));
        return;
      }

      try {
        var response = await ApiService.insertUser(userData);

        if (response?["status"] == "success") {
          // Save data to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("email", _emailController.text);
          await prefs.setString("user_type", _userType);
          await prefs.setString("full_name", _nameController.text);
          await prefs.setString("email_address", _emailController.text);
          await prefs.setString("phone_number", _phoneController.text);
          await prefs.setString("address", _addressController.text);
          await prefs.setString("gender", _gender);
          await prefs.setString("date_of_birth", _dobController.text);
          await prefs.setString("password", _passwordController.text);
          await prefs.setString("address_line_1", _addressLine1Controller.text);
          await prefs.setString("address_line_2", _addressLine2Controller.text);
          await prefs.setString("landmark", _landmarkController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration successful")),
          );

          // Redirect to login
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, "/login");
          });

        } else {
          final errorMsg = response?["message"];
          String displayMessage;

          if (errorMsg != null && errorMsg.toString().toLowerCase().contains("email")) {
            displayMessage = "An account already exists with this email address";
          } else {
            displayMessage = "Something went wrong. Please try again.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(displayMessage)),
          );
        }
      } catch (e) {
        // Avoid printing raw error objects
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields correctly and agree to terms")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nameController, "Full Name", "Enter your full name"),
                _buildTextField(_emailController, "Email Address", "Enter your email", TextInputType.emailAddress),
                _buildPasswordField(_passwordController, "Password", "Enter your password", _isPasswordVisible, () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                }),
                _buildPasswordField(_confirmPasswordController, "Confirm Password", "Re-enter your password", _isConfirmPasswordVisible, () {
                  setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                }),
                _buildTextField(_phoneController, "Phone Number", "Enter your phone number", TextInputType.phone),
                _buildDateField("Date of Birth"),
                _buildDropdownField("Gender"),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isAddressExpanded = !_isAddressExpanded),
                      child: Row(
                        children: [
                          Icon(_isAddressExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          SizedBox(width: 8),
                          Text("Enter Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (_isAddressExpanded)
                      Column(
                        children: [
                          _buildAddressField("Address"),
                          _buildTextField(_addressLine1Controller, "Address Line 1", "Enter address line 1"),
                          _buildTextField(_addressLine2Controller, "Address Line 2", "Enter address line 2"),
                          _buildTextField(_landmarkController, "Landmark", "Enter landmark"),
                          _buildTextField(_pincodeController, "Pincode", "Enter your area pincode", TextInputType.number),
                        ],
                      )
                  ],
                ),

                SizedBox(height: 10),

                _buildUserTypeSelection(),
                _buildCheckboxWithButton("I agree to the ", "Terms and Conditions"),
                SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _registerUser, child: Text("Register"))
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, "/login"),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
              ],

            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return _buildTextField(_dobController, label, "DD / MM / YYYY", TextInputType.text, true, Icons.calendar_today, () => _pickDate(context));
  }

  Widget _buildAddressField(String label) {
    return _buildTextField(
      _addressController,
      label,
      "Enter your address",
      TextInputType.text,
      false,
    );
  }

  Widget _buildDropdownField(String label) {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      items: ["Male", "Female", "Other"].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
      onChanged: (value) => setState(() => _gender = value!),
    );
  }

  Widget _buildCheckboxWithButton(String text, String buttonText) {
    return Row(
      children: [
        Checkbox(value: _agreeToTerms, onChanged: (value) => setState(() => _agreeToTerms = value ?? false)),
        Text(text),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermsAndConditionsScreen())),
          child: Text(buttonText, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      [TextInputType keyboardType = TextInputType.text, bool readOnly = false, IconData? icon, VoidCallback? onTap]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
          suffixIcon: icon != null ? IconButton(icon: Icon(icon), onPressed: onTap) : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label.";
          }
          if (label == "Email Address" && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return "Please enter a valid email address.";
          }
          if (label == "Phone Number" && value.length < 10) {
            return "Phone number must be at least 10 digits.";
          }
          if (label == "Pincode" && value.length < 4) {
            return "Please enter a valid pincode.";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller,
      String label,
      String hint,
      bool isVisible,
      VoidCallback toggleVisibility,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible, // 👈 hide text if not visible
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label.";
          if (label == "Password" && value.length < 6) {
            return "Password must be at least 6 characters.";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        Text("User Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(child: RadioListTile(value: "Tailor", groupValue: _userType, title: Text("Tailor"), onChanged: (value) => setState(() => _userType = value!))),
            Expanded(child: RadioListTile(value: "Vendor", groupValue: _userType, title: Text("Vendor"), onChanged: (value) => setState(() => _userType = value!))),
          ],
        ),
      ],
    );
  }

}