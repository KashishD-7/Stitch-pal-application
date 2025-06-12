import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.orderPhoto.isNotEmpty)
              Image.network(order.orderPhoto, height: 200, width: double.infinity, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text("Customer: ${order.customerName}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Contact: ${order.contactNumber}"),
            Text("Clothing Types: ${_formatClothingTypes(order.clothingTypes)}"),
            Text("Instructions: ${order.additionalInstructions}"),
            Text("Price: ₹${order.price}"),
            Text("Status: ${order.status}"),
          ],
        ),
      ),
    );
  }

  // Function to handle both List<String> and String
  String _formatClothingTypes(dynamic clothingTypes) {
    if (clothingTypes is List<String>) {
      return clothingTypes.join(', '); // If already a list
    } else if (clothingTypes is String) {
      return clothingTypes.split(',').map((e) => e.trim()).join(', '); // Convert to List and join
    }
    return "N/A"; // Fallback
  }
}
