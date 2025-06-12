import 'package:flutter/material.dart';

class CustomerDetailsPage extends StatefulWidget {
  @override
  _CustomerDetailsPageState createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final Map<String, TextEditingController> _controllers = {
    "Chest": TextEditingController(text: "42 inches"),
    "Waist": TextEditingController(text: "34 inches"),
    "Inseam": TextEditingController(text: "32 inches"),
    "Shoulders": TextEditingController(text: "18 inches"),
    "Sleeve Length": TextEditingController(text: "25 inches"),
    "Neck": TextEditingController(text: "16 inches"),
    "Hip": TextEditingController(text: "40 inches"),
    "Thigh": TextEditingController(text: "22 inches"),
  };

  void _saveMeasurements() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Measurements saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Customer Details"),
      ),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "John Anderson",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 4),
                  Text("Last updated: 2023-08-15"),
                ],
              ),
              SizedBox(height: 16),
              Text("Body Measurements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ..._controllers.entries.map((entry) => _buildEditableMeasurementItem(entry.key, entry.value)).toList(),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveMeasurements,
                icon: Icon(Icons.save),
                label: Text("Save Measurements"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              SizedBox(height: 24),
              Text("Measurement History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildHistoryItem("2023-08-15", [
                "Chest : 41 inches → 42 inches",
                "Waist : 33 inches → 34 inches",
              ]),
              _buildHistoryItem("2023-08-10", [
                "Sleeve Length : 24 inches → 25 inches",
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableMeasurementItem(String title, TextEditingController controller) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: TextField(
          controller: controller,
          decoration: InputDecoration(border: InputBorder.none),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String date, List<String> changes) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 4),
                Text(date, style: TextStyle(fontSize: 14)),
                Spacer(),
                Icon(Icons.delete, color: Colors.grey),
              ],
            ),
            SizedBox(height: 4),
            ...changes.map((change) => Text(change, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}
