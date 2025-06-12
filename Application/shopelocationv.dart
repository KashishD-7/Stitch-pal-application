import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ShopDetailsScreen1 extends StatefulWidget {
  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _businessHoursController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // For mobile platforms
  File? _imageFile;

  // For web platforms
  Uint8List? _webImage;
  String? _webImageName;

  // To handle image caching/refresh issues
  String _existingImageUrl = '';
  String _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userType = prefs.getString('user_type');

      // Only proceed if user is a Vendor
      if (userType != 'Vendor') {
        setState(() {
          _errorMessage = 'This page is only available for Vendor accounts';
          _isLoading = false;
        });
        return;
      }

      // Fetch shop details from API
      final response = await http.get(
        Uri.parse('http://172.16.6.10:8000/api/vendor-shop-details/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _shopNameController.text = data['shop_name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _locationController.text = data['location'] ?? '';
          _businessHoursController.text = data['business_hours'] ?? '';

          // Update image URL with version to prevent caching
          _existingImageUrl = data['image'] ?? '';
          _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load shop details. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Compress image to reduce size
    );

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
    setState(() {
      _locationController.text = "Fetching location...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Location services are disabled."),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _locationController.text = "";
      });
      return;
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Location permission denied."),
          backgroundColor: Colors.red,
        ));
        setState(() {
          _locationController.text = "";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Location permissions are permanently denied."),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _locationController.text = "";
      });
      return;
    }

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _locationController.text = "${position.latitude},${position.longitude}";
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Location updated successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error getting location: $e"),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _locationController.text = "";
      });
    }
  }

  Future<void> _updateShopDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String apiUrl = "http://172.16.6.10:8000/api/update-vendor-shop/";

      // Check if we're just updating text fields
      if (_imageFile == null && _webImage == null) {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'shop_name': _shopNameController.text,
            'address': _addressController.text,
            'location': _locationController.text,
            'business_hours': _businessHoursController.text,
          }),
        );

        if (response.statusCode == 200) {
          _handleSuccess();
        } else {
          _showErrorMessage('Failed to update shop details. Error: ${response.statusCode}');
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
              'address': _addressController.text,
              'location': _locationController.text,
              'business_hours': _businessHoursController.text,
              'image': base64Image,
              'image_name': _webImageName ?? 'web_image.jpg',
            }),
          );

          if (response.statusCode == 200) {
            _handleSuccess();
          } else {
            _showErrorMessage('Failed to update shop details. Error: ${response.statusCode}');
          }
        }
      } else {
        // For mobile platforms
        var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['shop_name'] = _shopNameController.text;
        request.fields['address'] = _addressController.text;
        request.fields['location'] = _locationController.text;
        request.fields['business_hours'] = _businessHoursController.text;

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
          _handleSuccess();
        } else {
          _showErrorMessage('Failed to update shop details. Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handleSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Shop details updated successfully"), backgroundColor: Colors.green),
    );

    // Clear selected images
    setState(() {
      _imageFile = null;
      _webImage = null;
      _webImageName = null;

      // Force cache invalidation with a unique timestamp
      _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();
      _existingImageUrl = ''; // Clear existing URL to force reload
    });

    // Fetch fresh data from the server
    _fetchShopDetails();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showBusinessHoursDialog() {
    final TextEditingController tempController = TextEditingController(
      text: _businessHoursController.text,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Business Hours'),
        content: Container(
          width: double.maxFinite,  // Make dialog wider
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your business hours for each day:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: tempController,
                  maxLines: 10,  // Increased from 7 to 10
                  minLines: 7,   // Set minimum lines
                  decoration: InputDecoration(
                    hintText: 'Example:\nMonday: 9:00 AM - 6:00 PM\nTuesday: 9:00 AM - 6:00 PM\nWednesday: 9:00 AM - 6:00 PM\nThursday: 9:00 AM - 6:00 PM\nFriday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 15),
                Text(
                  'Tip: Be clear about your opening and closing times for each day of the week.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _businessHoursController.text = tempController.text;
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Shop Details"),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 70, color: Colors.red),
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[100]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            "Shop Image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: screenWidth > 600 ? 200 : 150,
                                  height: screenWidth > 600 ? 200 : 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: !kIsWeb && _imageFile != null
                                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                                        : _webImage != null
                                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                                        : _existingImageUrl.isNotEmpty
                                        ? Image.network(
                                      _existingImageUrl + "?v=$_imageVersion",
                                      fit: BoxFit.cover,
                                      cacheWidth: null,
                                      cacheHeight: null,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(Icons.store, size: 80, color: Colors.grey),
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    )
                                        : Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.store, size: 80, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add_a_photo, color: Colors.white, size: screenWidth > 600 ? 24 : 20),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          builder: (context) => Container(
                                            padding: EdgeInsets.symmetric(vertical: 20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "Select Image Source",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 30,
                                                          backgroundColor: Colors.blue[100],
                                                          child: IconButton(
                                                            icon: Icon(Icons.photo_camera, color: Colors.blue, size: 30),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                              _pickImage(ImageSource.camera);
                                                            },
                                                          ),
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text("Camera"),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 30,
                                                          backgroundColor: Colors.green[100],
                                                          child: IconButton(
                                                            icon: Icon(Icons.photo_library, color: Colors.green, size: 30),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                              _pickImage(ImageSource.gallery);
                                                            },
                                                          ),
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text("Gallery"),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Shop Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            "Shop Name",
                            "Enter your shop name",
                            _shopNameController,
                            icon: Icons.store,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Shop name is required";
                              }
                              if (value.length < 3) {
                                return "Shop name must be at least 3 characters";
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            "Shop Address",
                            "Enter your shop address",
                            _addressController,
                            icon: Icons.location_on,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Shop address is required";
                              }
                              if (value.length < 5) {
                                return "Please enter a complete address";
                              }
                              return null;
                            },
                          ),
                          _buildLocationField(),
                          _buildBusinessHoursField(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _updateShopDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: _isSaving
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("Saving...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                        : Text("Update Shop Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      String hint,
      TextEditingController controller, {
        int maxLines = 1,
        IconData? icon,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator ?? (value) => value!.isEmpty ? "$label is required" : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          maxLines: maxLines,
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Location Coordinates",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.my_location, size: 16),
              label: Text("Get Current Location"),
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: "Latitude, Longitude coordinates",
            prefixIcon: Icon(Icons.gps_fixed),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          readOnly: true,
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBusinessHoursField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Business Hours",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.access_time, size: 18),
              label: Text("Set Hours"),
              onPressed: _showBusinessHoursDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _businessHoursController.text.isEmpty
                  ? Center(
                child: Text(
                  "No business hours set",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              )
                  : Text(
                _businessHoursController.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}