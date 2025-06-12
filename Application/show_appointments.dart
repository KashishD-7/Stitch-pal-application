import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentListScreen extends StatefulWidget {
  @override
  _AppointmentListScreenState createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  String _errorMessage = '';
  String _userType = 'tailor'; // Default to tailor

  // API URL - replace with your Django server URL
  final String apiUrl = 'http://172.16.6.10:8000/api/appointments/';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type') ?? 'tailor';

      setState(() {
        _userType = userType;
      });

      _fetchAppointments();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userType = prefs.getString('user_type') ?? 'tailor';

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      // Print userType to debug
      print('User type: $userType');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Print response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final List<dynamic> appointmentsJson = jsonDecode(response.body);
        setState(() {
          _appointments = appointmentsJson
              .map((json) => Appointment.fromJson(json))
              .toList();
          _appointments.sort((a, b) {
            int dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) return dateCompare;
            return a.timeSlot.compareTo(b.timeSlot);
          });

          // Debug: print the number of appointments
          print('Number of appointments loaded: ${_appointments.length}');
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load appointments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _deleteAppointment(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$apiUrl$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Remove the appointment from the list
        setState(() {
          _appointments.removeWhere((appointment) => appointment.id == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete appointment: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToEditScreen(Appointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: appointment,
          onUpdate: () {
            _fetchAppointments(); // Refresh the list after update
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userType == 'vendor' ? "My Bookings" : "My Appointments"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
            : _appointments.isEmpty
            ? Center(child: Text(_userType == 'vendor'
            ? "No bookings found"
            : "No appointments found"))
            : _buildAppointmentsList(),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    // Group appointments by date
    Map<String, List<Appointment>> groupedAppointments = {};

    for (var appointment in _appointments) {
      String dateKey = DateFormat('yyyy-MM-dd').format(appointment.date);
      if (!groupedAppointments.containsKey(dateKey)) {
        groupedAppointments[dateKey] = [];
      }
      groupedAppointments[dateKey]!.add(appointment);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: groupedAppointments.length,
      itemBuilder: (context, index) {
        String dateKey = groupedAppointments.keys.elementAt(index);
        List<Appointment> dayAppointments = groupedAppointments[dateKey]!;
        DateTime date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: index > 0 ? 24 : 0, bottom: 8),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
            ...dayAppointments.map((appointment) => _buildAppointmentCard(appointment)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.timeSlot,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Show edit/delete buttons for both tailors and vendors
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToEditScreen(appointment),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Appointment'),
                            content: Text('Are you sure you want to delete this appointment?'),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text('Delete'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteAppointment(appointment.id);
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            Divider(),
            // Display different information based on user type
            _userType == 'vendor'
                ? _buildVendorInfoCard(appointment)  // Show tailor info for vendor
                : _buildTailorInfoCard(appointment), // Show vendor info for tailor
          ],
        ),
      ),
    );
  }

  // Information card layout for vendors (shows tailor's info)
  Widget _buildVendorInfoCard(Appointment appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Tailor Name', appointment.name),
        _buildInfoRow('Contact', appointment.contact),
        if (appointment.remark != null && appointment.remark!.isNotEmpty)
          _buildInfoRow('Purpose', appointment.remark!),
      ],
    );
  }

  // Information card layout for tailors (shows vendor info)
  Widget _buildTailorInfoCard(Appointment appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appointment.vendorName != null)
          _buildInfoRow('Vendor', appointment.vendorName!),
        _buildInfoRow('Name', appointment.name),
        _buildInfoRow('Contact', appointment.contact),
        if (appointment.remark != null && appointment.remark!.isNotEmpty)
          _buildInfoRow('Purpose', appointment.remark!),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Appointment Model class
class Appointment {
  final int id;
  final DateTime date;
  final String timeSlot;
  final String name;
  final String contact;
  final String? remark;
  final DateTime createdAt;
  final int? vendorId;
  final String? vendorName;

  Appointment({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.name,
    required this.contact,
    this.remark,
    required this.createdAt,
    this.vendorId,
    this.vendorName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      date: DateTime.parse(json['date']),
      timeSlot: json['time_slot'],
      name: json['name'],
      contact: json['contact'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['created_at']),
      vendorId: json['vendor'] ?? json['vendor_id'],
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
    );
  }
}

// Edit Appointment Screen
class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onUpdate;

  EditAppointmentScreen({
    required this.appointment,
    required this.onUpdate,
  });

  @override
  _EditAppointmentScreenState createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  bool _isLoading = false;

  late TextEditingController _timeSlotController;
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _remarkController;
  late TextEditingController _vendorNameController;

  // API URL - replace with your Django server URL
  final String apiUrl = 'http://172.16.6.10:8000/api/appointments/';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.date;
    _timeSlotController = TextEditingController(text: widget.appointment.timeSlot);
    _nameController = TextEditingController(text: widget.appointment.name);
    _contactController = TextEditingController(text: widget.appointment.contact);
    _remarkController = TextEditingController(text: widget.appointment.remark ?? '');
    _vendorNameController = TextEditingController(text: widget.appointment.vendorName ?? '');
  }

  @override
  void dispose() {
    _timeSlotController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _remarkController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        Map<String, dynamic> appointmentData = {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'time_slot': _timeSlotController.text,
          'name': _nameController.text,
          'contact': _contactController.text,
          'remark': _remarkController.text,
          // We don't update vendor here as it would require vendor selection dropdown
          // To update vendor, you'd need to implement a vendor selection UI
        };

        final response = await http.put(
          Uri.parse('${apiUrl}${widget.appointment.id}/'),
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
          widget.onUpdate();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update appointment: ${response.statusCode}'),
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
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Appointment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Appointment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Date selection
                  ListTile(
                    title: Text('Appointment Date'),
                    subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
                    trailing: Icon(Icons.calendar_today),
                    tileColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                  SizedBox(height: 20),

                  // Display vendor name (read-only)
                  if (widget.appointment.vendorName != null && widget.appointment.vendorName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _vendorNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Vendor',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),

                  // Time slot
                  buildTextField('Time Slot', _timeSlotController),

                  // Name
                  buildTextField('Name', _nameController),

                  // Contact
                  buildTextField('Contact', _contactController),

                  // Purpose/Remark
                  buildTextField('Purpose', _remarkController, isMultiline: true),

                  SizedBox(height: 20),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Update Appointment', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}