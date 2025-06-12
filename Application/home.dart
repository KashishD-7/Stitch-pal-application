import 'package:flutter/material.dart';
import 'profile.dart';
import 'order.dart';
import 'measurement.dart';
import 'shopelocation.dart';
import 'ordercustomize.dart';
import 'appointment.dart';
import 'stitching.dart';
import 'settings.dart';
import '../models/order.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tailor_orders.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Order> _pendingOrders = [];
  bool _isLoadingOrders = true;
  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  void _loadPendingOrders() async {
    try {
      List<Order> orders = await fetchPendingOrders();
      setState(() {
        _pendingOrders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      print("Error loading pending orders: $e");
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              "StitchPro",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.black), // Settings button
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),

          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orders & Storage Overview
              _buildOrderSummary(),

              SizedBox(height: 20),

              // Quick Actions
              Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildQuickActions(context),

              SizedBox(height: 20),

              // Recent Orders
              _buildRecentOrders(),

              SizedBox(height: 20),


            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Future<Map<String, dynamic>> fetchOrderStatistics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return {
        "today": 0,
        "pending": 0,
        "total": 0
      };
    }

    final response = await http.get(
      Uri.parse("http://172.16.6.10:8000/api/orders/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      List<Order> allOrders = jsonData.map((order) => Order.fromJson(order)).toList();

      // Get today's date
      DateTime now = DateTime.now();
      String todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Count today's orders
      int todayOrdersCount = allOrders.where((order) {
        return order.createdAt.startsWith(todayDate);
      }).length;

      // Count pending orders
      int pendingOrdersCount = allOrders.where((order) => order.status == "Pending").length;

      // Get total number of orders (all time)
      int totalOrdersCount = allOrders.length;

      return {
        "today": todayOrdersCount,
        "pending": pendingOrdersCount,
        "total": totalOrdersCount
      };
    } else {
      throw Exception('Failed to load order statistics');
    }
  }

  Widget _buildOrderSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchOrderStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
            ),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
            ),
            child: Center(child: Text("Error loading statistics")),
          );
        } else {
          final stats = snapshot.data ?? {"today": 0, "pending": 0, "total": 0};

          return Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(stats["today"].toString(), "Today's Orders", Colors.blue),
                _buildSummaryItem(stats["pending"].toString(), "Pending", Colors.orange),
                _buildSummaryItem(stats["total"].toString(), "Total Orders", Colors.green),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    List<Map<String, dynamic>> actions = [
      {"icon": Icons.list, "label": "Order Management", "route": OrderHistoryScreen()},
      {"icon": Icons.storage, "label": "Storage", "route": MeasurementStorageScreen()},
      {"icon": Icons.store, "label": "Shop Location", "route": ShopDetailsScreen()},
      {"icon": Icons.build, "label": "Order Customize", "route": CustomizeOrderScreen1()},
      {"icon": Icons.calendar_today, "label": "Appointments", "route": AppointmentScreen()},
      {"icon": Icons.design_services, "label": "Stitching", "route": StitchingMethodsScreen()},
      {"icon": Icons.design_services, "label": "My Orders", "route": TailorOrdersScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (actions[index]["route"] != null){
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => actions[index]["route"]),
              );
            }
      },
          child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: Row(
            children: [
              Icon(actions[index]["icon"], color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  actions[index]["label"],
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildRecentOrders() {
    if (_isLoadingOrders) {
      return Center(child: CircularProgressIndicator());
    } else if (_pendingOrders.isEmpty) {
      return Center(child: Text("No pending orders found"));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Recent Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
                },
                child: Text("View All", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: _pendingOrders.map((order) => _buildOrderCard(order)).toList(),
          ),
        ],
      );
    }
  }



  Future<List<Order>> fetchPendingOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("http://172.16.6.10:8000/api/orders/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      print(jsonData);
      jsonData.map((order) {
        print("Order Status: ${order['status']}, isAccepted: ${order['is_accepted']}");
        return Order.fromJson(order);
      });

      return jsonData
          .map((order) => Order.fromJson(order))
          .where((order) =>
      order.status == "Pending" && order.isAccepted == "Pending")
          .toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }


  Future<void> updateOrderDecision(int orderId, String decision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://172.16.6.10:8000/api/orders/$orderId/decision/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'decision': decision}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _pendingOrders.removeWhere((order) => order.id == orderId);
      });
      print("Order $decision successfully");
    } else {
      print("Failed to update decision: ${response.body}");
    }
  }


  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          ListTile(
            leading: order.orderPhoto.isNotEmpty
                ? Image.network(order.orderPhoto, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(order.customerName, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.clothingTypes, style: TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(order.createdAt, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                order.status,
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (order.isAccepted == "Pending")
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => updateOrderDecision(order.id, "Accepted"),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.close, color: Colors.white),
                    label: Text("Decline"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => updateOrderDecision(order.id, "Declined"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }




  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
          );
        }
        else if (index == 2) {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => AppointmentScreen()),
          );
        }
        else if(index == 3){
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => CreateProfileScreen()),
          );
        }
        else if (index == 4) {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => TailorOrdersScreen()),
          );
        }
      },

      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "My Orders"),
      ],
    );
  }

}
