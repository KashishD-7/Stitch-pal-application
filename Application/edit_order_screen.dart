import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class EditOrderScreen extends StatefulWidget {
  final Order order;

  EditOrderScreen({required this.order});

  @override
  _EditOrderScreenState createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _instructionsController;
  late TextEditingController _priceController;
  String selectedStatus = "";

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.order.customerName);
    _contactNumberController = TextEditingController(text: widget.order.contactNumber);
    _instructionsController = TextEditingController(text: widget.order.additionalInstructions);
    _priceController = TextEditingController(text: widget.order.price.toString());
    selectedStatus = widget.order.status; // Load the current status
  }

  Future<void> _updateOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse("http://172.16.6.10:8000/api/orders/${widget.order.id}/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "customer_name": _customerNameController.text,
        "contact_number": _contactNumberController.text,
        "additional_instructions": _instructionsController.text,
        "price": _priceController.text,
        "status": selectedStatus, // Include updated status
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // Return to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update order")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Order")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField("Customer Name", _customerNameController),
            _buildTextField("Contact Number", _contactNumberController),
            _buildTextField("Additional Instructions", _instructionsController, maxLines: 3),
            _buildTextField("Price", _priceController),
            SizedBox(height: 15),

            // Status Dropdown
            Text("Order Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: ["Pending", "Completed", "Canceled"].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStatus = newValue!;
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _updateOrder,
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }
}
