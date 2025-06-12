import 'package:flutter/material.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  String? _resetToken;

  // Send OTP to email
  Future<void> _requestPasswordReset() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your email address')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.requestPasswordReset({'email_address': email});
      if (response['status'] == 'success') {
        setState(() => _currentStep = 1);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'OTP sent successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to send OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    String email = _emailController.text.trim();
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter the OTP')));
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyOtp({
        'email_address': email,
        'otp': otp,
      });

      if (response['status'] == 'success') {
        _resetToken = response['reset_token'];
        setState(() => _currentStep = 2);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'OTP verified')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Invalid OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set new password
  Future<void> _setNewPassword() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your new password')));
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password must be at least 8 characters')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_resetToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Missing reset token. Please try again.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.setNewPassword({
        'email_address': email,
        'reset_token': _resetToken,
        'new_password': password,
      });

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Password reset successfully')));
        Navigator.of(context).pop(); // Go back to login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to reset password')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your email address')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.requestPasswordReset({'email_address': email});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'OTP resent successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Reset Password', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Icon(Icons.lock_reset, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                _getStepTitle(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildProgressIndicator(),
              SizedBox(height: 20),
              _buildCurrentStepContent(),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : _buildActionButton(),
              SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Login', style: TextStyle(fontSize: 16, color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password?';
      case 1:
        return 'Verify OTP';
      case 2:
        return 'Create New Password';
      default:
        return 'Reset Password';
    }
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressStep(0, 'Email'),
        _buildProgressLine(0),
        _buildProgressStep(1, 'OTP'),
        _buildProgressLine(1),
        _buildProgressStep(2, 'Password'),
      ],
    );
  }

  Widget _buildProgressStep(int step, String label) {
    bool isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                (step + 1).toString(),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    bool isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.blue : Colors.grey.shade300,
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            Text(
              'Enter your email address to receive a verification code',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Enter your email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Text(
              'Enter the 6-digit code sent to your email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.pin_outlined),
                hintText: 'Enter OTP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                counterText: '',
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Didn't receive the code? "),
                TextButton(
                  onPressed: _isLoading ? null : _resendOTP,
                  child: Text('Resend'),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            Text(
              'Create a new password for your account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Enter new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Confirm new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Password must be at least 8 characters long',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: () {
        if (_currentStep == 0) {
          _requestPasswordReset();
        } else if (_currentStep == 1) {
          _verifyOtp();
        } else if (_currentStep == 2) {
          _setNewPassword();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        _getButtonText(),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Send Verification Code';
      case 1:
        return 'Verify Code';
      case 2:
        return 'Reset Password';
      default:
        return 'Continue';
    }
  }
}
