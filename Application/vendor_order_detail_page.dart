import 'package:flutter/material.dart';

class VendorOrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const VendorOrderDetailPage({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow("Customer Name", order['customer_name']),
                _buildRow("Clothing Type", order['clothing_types']),
                _buildRow("Description", order['description'] ?? "N/A"),
                _buildRow("Price", "₹${order['price']}"),
                _buildRow("Status", order['status']),
                _buildRow("Created At", order['created_at'].toString().substring(0, 10)),
                if (order['tailor'] != null)
                  _buildRow("Tailor Assigned", order['tailor']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
