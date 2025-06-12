import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'vendor_order_detail_page.dart';

class VendorAllOrdersPage extends StatefulWidget {
  @override
  _VendorAllOrdersPageState createState() => _VendorAllOrdersPageState();
}

class _VendorAllOrdersPageState extends State<VendorAllOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVendorOrders();
  }

  Future<void> fetchVendorOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://172.16.6.10:8000/api/vendor-orders/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _orders = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      print("Failed to load vendor orders");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(child: Text("No orders found."))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          Color getStatusColor(String status) {
            switch (status.toLowerCase()) {
              case 'pending':
                return Colors.orange;
              case 'accepted':
                return Colors.green;
              case 'canceled':
                return Colors.red;
              default:
                return Colors.grey;
            }
          }
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            elevation: 3,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorOrderDetailPage(order: order),
                  ),
                );
              },
              title: Text(order['customer_name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Clothing: ${order['clothing_types']}"),
                  Text("Price: ₹${order['price']}"),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text("Status: "),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: getStatusColor(order['status']),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          order['status'],
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Text(order['created_at'].toString().substring(0, 10)),
            ),
          );
        },
      ),
    );
  }
}
