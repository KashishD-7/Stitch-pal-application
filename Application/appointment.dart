import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: AppointmentScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class Vendor {
  final int id;
  final String fullName;
  final String shopName;

  Vendor({required this.id, required this.fullName, required this.shopName});

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['user_id'],
      fullName: json['full_name'],
      shopName: json['shop_name'] ?? '',
    );
  }

  @override
  String toString() {
    return '$fullName (${shopName.isNotEmpty ? shopName : "No Shop"})';
  }
}


class _AppointmentScreenState extends State<AppointmentScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  List<Vendor> vendors = [];
  Vendor? selectedVendor;

  final _formKey = GlobalKey<FormState>();

  TextEditingController timeSlotController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController purposeController = TextEditingController();

  Future<void> _fetchVendors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://172.16.6.10:8000/api/vendor/'), // Adjust URL if needed
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      setState(() {
        vendors = data.map((json) => Vendor.fromJson(json)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load vendors")),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }


  // API URL - replace with your Django server URL
  final String apiUrl = 'http://172.16.6.10:8000/api/appointments/';


  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate() && _selectedDay != null) {
      setState(() {
        _isLoading = true;

      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token'); // Replace with your key

        // Format the date as YYYY-MM-DD
        String formattedDate = "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";

        // Create appointment data
        Map<String, dynamic> appointmentData = {
          'date': formattedDate,
          'time_slot': timeSlotController.text,
          'name': nameController.text,
          'contact': contactController.text,
          'purpose': purposeController.text,
          'vendor': selectedVendor?.id,
        };
        print("Selected vendor ID: ${selectedVendor?.id}");
        // Send HTTP POST request to Django API
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(appointmentData),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          // Success! Show success message
          final responseData = jsonDecode(response.body);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Appointment Booked Successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form fields
          _clearForm();
        } else {
          // Show error message
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${responseData['message'] ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a date!")),
        );
      }
    }
  }

  void _clearForm() {
    timeSlotController.clear();
    nameController.clear();
    contactController.clear();
    purposeController.clear();
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Appointment Scheduling")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Book your fittings and consultations with ease. Use the calendar to select available slots and receive reminders.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 10),

                // Calendar Section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200], // Light background
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),

                if (_selectedDay == null) // Show error message if no date is selected
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Please select a date!", style: TextStyle(color: Colors.red)),
                  ),

                SizedBox(height: 20),

                // Display selected date
                if (_selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      "Selected Date: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                // Booking Form
                Text("Booking Form", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField("Select a time slot", timeSlotController),
                      buildTextField("Enter your name", nameController),
                      buildTextField("Enter contact info", contactController),
                      buildTextField("Enter purpose of appointment", purposeController),
                      SizedBox(height: 10),

                      // Vendor Dropdown
                      DropdownButtonFormField<Vendor>(
                        value: selectedVendor,
                        items: vendors.map((vendor) {
                          return DropdownMenuItem(
                            value: vendor,
                            child: Text(vendor.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVendor = value;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Please select a vendor' : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          hintText: "Select Vendor",
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Appointment Booked Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Book Appointment"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "This field is required";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
      ),
    );
  }
}