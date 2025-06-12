import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'measurement_form.dart';

class MeasurementStorageScreen extends StatefulWidget {
  const MeasurementStorageScreen({Key? key}) : super(key: key);

  @override
  State<MeasurementStorageScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementStorageScreen> {
  List measurements = [];
  String? token;

  @override
  void initState() {
    super.initState();
    fetchMeasurements();
  }

  Future<void> fetchMeasurements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://172.16.6.10:8000/api/measurements/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        measurements = json.decode(response.body);
      });
    } else {
      print('Error fetching measurements: ${response.body}');
    }
  }

  void deleteMeasurement(int id) async {
    final response = await http.delete(
      Uri.parse('http://172.16.6.10:8000/api/measurements/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 204) {
      setState(() {
        measurements.removeWhere((m) => m['id'] == id);
      });
    } else {
      print('Delete failed: ${response.body}');
    }
  }

  void navigateToForm({Map? measurement}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementForm(measurement: measurement),
      ),
    );
    fetchMeasurements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Measurements')),
      body: ListView.builder(
        itemCount: measurements.length,
        itemBuilder: (context, index) {
          var m = measurements[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text("Order ID: ${m['customer_name'] ?? 'null'}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Chest: ${m['chest']}"),
                  Text("Waist: ${m['waist']}"),
                  Text("Inseam: ${m['inseam']}"),
                ],
              ),
              trailing: Wrap(
                spacing: 12,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => navigateToForm(measurement: m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteMeasurement(m['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
