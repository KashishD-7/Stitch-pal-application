import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'customization_model.dart';

class CustomizeOrderScreen1 extends StatefulWidget {
  @override
  _CustomizeOrderScreenState createState() => _CustomizeOrderScreenState();
}

class _CustomizeOrderScreenState extends State<CustomizeOrderScreen1> {
  late Future<List<OrderCustomization>> _customizations;

  @override
  void initState() {
    super.initState();
    _customizations = fetchCustomizations();
  }

  Future<List<OrderCustomization>> fetchCustomizations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print("Token not found in SharedPreferences.");
      throw Exception("Token not found");
    }

    final url = "http://172.16.6.10:8000/api/customizationsv/"; // Use actual IP if on device
    print("Requesting: $url");
    print("Using Token: $token");

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => OrderCustomization.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing JSON: $e");
        throw Exception('Failed to parse customization data');
      }
    } else {
      throw Exception('Failed to load customizations. Status: ${response.statusCode}');
    }
  }

  void _showDetailsDialog(OrderCustomization custom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order: ${custom.orderName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${custom.orderName ?? 'N/A'}"),
            Text("Fabric: ${custom.fabricChoice ?? 'N/A'}"),
            Text("Style: ${custom.stylePreferences ?? 'N/A'}"),
            Text("Color: ${custom.colorOptions ?? 'N/A'}"),
            Text("Details: ${custom.additionalDetails ?? 'N/A'}"),
            Text("Created At: ${custom.createdAt?.substring(0, 10) ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Customizations")),
      body: FutureBuilder<List<OrderCustomization>>(
        future: _customizations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading customizations"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No customizations found"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final custom = snapshot.data![index];
                return ListTile(
                  title: Text("Customer: ${custom.orderName ?? 'N/A'}"),
                  subtitle: Text("Fabric: ${custom.fabricChoice ?? 'N/A'}"),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () => _showDetailsDialog(custom),
                );
              },
            );
          }
        },
      ),
    );
  }
}
