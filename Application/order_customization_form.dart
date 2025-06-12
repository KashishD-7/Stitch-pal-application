import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class OrderCustomizationForm extends StatefulWidget {
  final Order order;
  OrderCustomizationForm({required this.order});

  @override
  _OrderCustomizationFormState createState() => _OrderCustomizationFormState();
}

class _OrderCustomizationFormState extends State<OrderCustomizationForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController fabricController = TextEditingController();
  TextEditingController styleController = TextEditingController();
  TextEditingController colorController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  Future<void> saveCustomization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Map<String, dynamic> requestBody = {
      "order": widget.order.id,
      "fabric_choice": fabricController.text,
      "style_preferences": styleController.text,
      "color_options": colorController.text,
      "additional_details": detailsController.text,
    };

    final response = await http.post(
      Uri.parse("http://172.16.6.10:8000/api/customizations/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Customization Saved Successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to Save Customization")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customize Order #${widget.order.id}")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: fabricController,
                      decoration: InputDecoration(labelText: "Fabric Choice"),
                    ),
                    TextFormField(
                      controller: styleController,
                      decoration: InputDecoration(labelText: "Style Preferences"),
                    ),
                    TextFormField(
                      controller: colorController,
                      decoration: InputDecoration(labelText: "Color Options"),
                    ),
                    TextFormField(
                      controller: detailsController,
                      decoration: InputDecoration(labelText: "Additional Details"),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveCustomization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text("Save Customization", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
