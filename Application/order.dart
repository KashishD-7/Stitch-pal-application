import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import 'edit_order_screen.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> orders = [];
  String selectedStatus = "Completed";
  final String apiUrl = "http://172.16.6.10:8000/api/orders/";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');


    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You need to log in first!")));
      return;
    }

    final response = await http.get(
      Uri.parse("${apiUrl}?view=accepted"), // 🔥 ADD THIS LINE
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        orders = jsonData.map((order) => Order.fromJson(order)).toList();
      });
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<void> updateOrderStatus(int id, String newStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse("$apiUrl$id/update_status/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"status": newStatus}),
    );

    if (response.statusCode == 200) {
      fetchOrders();
    } else {
      throw Exception('Failed to update order status');
    }
  }

  Future<void> deleteOrder(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse("$apiUrl$id/"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 204) {
      setState(() {
        orders.removeWhere((order) => order.id == id);
      });
    } else {
      throw Exception('Failed to delete order');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Order> filteredOrders = orders.where((order) =>
    order.status == selectedStatus && order.isAccepted == "Accepted").toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Order History"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusTab("Completed", Colors.blue),
              _buildStatusTab("Pending", Colors.orange),
              _buildStatusTab("Canceled", Colors.red),
            ],
          ),
          SizedBox(height: 10),
          // Order List
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(child: Text("No orders found"))
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String status, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
      },
      child: Chip(
        label: Text(
          status,
          style: TextStyle(
            color: selectedStatus == status ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: selectedStatus == status ? color : Colors.grey[200],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        leading: order.orderPhoto.isNotEmpty
            ? Image.network(order.orderPhoto, width: 50, height: 50, fit: BoxFit.cover)
            : Icon(Icons.image, size: 50),
        title: Text(order.customerName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Contact: ${order.contactNumber}"),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "Edit") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditOrderScreen(order: order)),
              ).then((_) => fetchOrders());
            } else if (value == "Delete") {
              deleteOrder(order.id);
            } else if (value == "View") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
              );
            }
          },
          itemBuilder: (context) {
            // Start with the menu items all orders should have
            List<PopupMenuItem<String>> menuItems = [
              PopupMenuItem(value: "View", child: Text("View Details")),
            ];

            // Only add Edit option if the status is not "Completed"
            if (order.status != "Completed") {
              menuItems.add(PopupMenuItem(value: "Edit", child: Text("Edit Order")));
            }

            // Add Delete option for all orders
            menuItems.add(PopupMenuItem(value: "Delete", child: Text("Delete Order")));

            return menuItems;
          },
        ),
      ),
    );
  }
}
