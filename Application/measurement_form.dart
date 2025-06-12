import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MeasurementForm extends StatefulWidget {
  final Map? measurement;

  const MeasurementForm({super.key, this.measurement});

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  List orders = [];
  String? token;
  int? selectedOrder;
  double? chest, waist, inseam, shoulders, sleeveLength;

  @override
  void initState() {
    super.initState();
    loadTokenAndOrders();

    if (widget.measurement != null) {
      selectedOrder = widget.measurement!['order'];
      chest = widget.measurement!['chest'];
      waist = widget.measurement!['waist'];
      inseam = widget.measurement!['inseam'];
      shoulders = widget.measurement!['shoulders'];
      sleeveLength = widget.measurement!['sleeve_length'];
    }
  }

  Future<void> loadTokenAndOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://172.16.6.10:8000/api/accepted-orders/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        orders = json.decode(response.body);
      });
    } else {
      print('Error loading orders: ${response.body}');
    }
  }

  void saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    var data = {
      'order': selectedOrder,
      'chest': chest,
      'waist': waist,
      'inseam': inseam,
      'shoulders': shoulders,
      'sleeve_length': sleeveLength,
    };

    final isEditing = widget.measurement != null;
    final url = isEditing
        ? 'http://172.16.6.10:8000/api/measurements/${widget.measurement!['id']}/'
        : 'http://172.16.6.10:8000/api/measurements/';

    final response = await (isEditing
        ? http.put(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(data))
        : http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(data)));

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      print('Save failed: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.measurement != null ? 'Edit Measurement' : 'Add Measurement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField(
                value: selectedOrder,
                items: orders.map<DropdownMenuItem<int>>((order) {
                  return DropdownMenuItem<int>(
                    value: order['id'],
                    child: Text('Order ${order['id']} - ${order['customer_name']}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedOrder = value),
                decoration: const InputDecoration(labelText: 'Order'),
                validator: (value) => value == null ? 'Please select an order' : null,
              ),
              ...['Chest', 'Waist', 'Inseam', 'Shoulders', 'Sleeve Length'].map((label) {
                final field = label.toLowerCase().replaceAll(' ', '_');
                return TextFormField(
                  initialValue: widget.measurement != null ? widget.measurement![field].toString() : '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: label),
                  onSaved: (value) {
                    double parsed = double.tryParse(value ?? '0') ?? 0;
                    switch (field) {
                      case 'chest':
                        chest = parsed;
                        break;
                      case 'waist':
                        waist = parsed;
                        break;
                      case 'inseam':
                        inseam = parsed;
                        break;
                      case 'shoulders':
                        shoulders = parsed;
                        break;
                      case 'sleeve_length':
                        sleeveLength = parsed;
                        break;
                    }
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveMeasurement,
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
