import 'package:flutter/material.dart';
import 'profile.dart';
import 'changepass.dart';
import 'register.dart'; // Replace with your actual registration screen

class SettingsScreen extends StatelessWidget {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation popup
              _showSuccessDialog(context);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Success"),
        content: Text("You have logged out successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close success popup
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()), // Redirect to Registration
                    (route) => false, // Clear all previous routes
              );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(15),
        children: [
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text("Profile Settings"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProfileScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.red),
            title: Text("Change Password"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.black),
            title: Text("Logout"),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}
