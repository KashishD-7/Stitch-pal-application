import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: StitchingMethodsScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class StitchingMethodsScreen extends StatefulWidget {
  @override
  _StitchingMethodsScreenState createState() => _StitchingMethodsScreenState();
}

class _StitchingMethodsScreenState extends State<StitchingMethodsScreen> {
  final Map<String, double> _stitchingPrices = {
    "Single Needle": 5.00,
    "Double Needle": 7.50,
    "Overlock": 4.00,
  };

  final Map<String, bool> _selectedMethods = {
    "Single Needle": false,
    "Double Needle": false,
    "Overlock": false,
  };

  double _calculateTotalCost() {
    double total = 0.0;
    _selectedMethods.forEach((method, isSelected) {
      if (isSelected) {
        total += _stitchingPrices[method] ?? 0.0;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stitching Methods"),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Stitching Techniques",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Stitching Techniques List
            buildStitchingMethod("Single Needle", "Basic stitch", "assets/single_needle.jpg"),
            buildStitchingMethod("Double Needle", "Double stitch", "assets/double_needle.jpg"),
            buildStitchingMethod("Overlock", "Edge finishing", "assets/overlock.jpg"),

            SizedBox(height: 20),
            Text(
              "Select Stitching Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Checkbox Selection for Multiple Stitching Methods
            buildCheckboxOption("Single Needle"),
            buildCheckboxOption("Double Needle"),
            buildCheckboxOption("Overlock"),

            SizedBox(height: 20),
            Text(
              "Cost Estimation",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Cost Estimation
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._selectedMethods.keys
                      .where((method) => _selectedMethods[method]!)
                      .map((method) => Text("$method - ${_stitchingPrices[method]!.toStringAsFixed(2)}")),
                  Divider(),
                  Text("Total: ${_calculateTotalCost().toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStitchingMethod(String title, String subtitle, String imagePath) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget buildCheckboxOption(String value) {
    return CheckboxListTile(
      title: Text(value),
      value: _selectedMethods[value],
      onChanged: (newValue) {
        setState(() {
          _selectedMethods[value] = newValue ?? false;
        });
      },
    );
  }
}
