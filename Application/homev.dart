import 'package:flutter/material.dart';
import 'profile.dart';
import 'orderv.dart';
import 'shopelocationv.dart';
import 'ordercustomizev.dart';
import 'show_appointments.dart';
import 'settings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'appointment_model.dart' as model; // assume model is in this file
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'vendor_all_orders.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen1(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomeScreen1 extends StatefulWidget {
  @override
  _HomeScreen1State createState() => _HomeScreen1State();
}

class _HomeScreen1State extends State<HomeScreen1> {
  // Add state variables
  bool _isLoadingStats = true;
  Map<String, dynamic> _orderStats = {"today": 0, "pending": 0, "total": 0};

  @override
  void initState() {
    super.initState();
    _loadOrderStatistics();
  }

  Future<void> _loadOrderStatistics() async {
    try {
      Map<String, dynamic> stats = await fetchOrderStatistics();
      setState(() {
        _orderStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      print("Error loading order statistics: $e");
      setState(() {
        _isLoadingStats = false;
      });
    }
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
      List<dynamic> allOrders = jsonData;

      // Get today's date
      DateTime now = DateTime.now();
      String todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Count today's orders
      int todayOrdersCount = allOrders.where((order) {
        return order['created_at'].toString().startsWith(todayDate);
      }).length;

      // Count pending orders
      int pendingOrdersCount = allOrders.where((order) => order['status'] == "Pending").length;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              "VenderPro",
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

              // Today's Appointments
              _buildAppointments(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildOrderSummary() {
    if (_isLoadingStats) {
      return Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
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
            _buildSummaryItem(_orderStats["today"].toString(), "Today's Orders", Colors.blue),
            _buildSummaryItem(_orderStats["pending"].toString(), "Pending", Colors.orange),
            _buildSummaryItem(_orderStats["total"].toString(), "Total Orders", Colors.green),
          ],
        ),
      );
    }
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
      {"icon": Icons.list, "label": "Order Placement", "route": NewTailoringOrderScreen()},
      {"icon": Icons.store, "label": "Shop Location", "route": ShopDetailsScreen1()},
      {"icon": Icons.build, "label": "Order Customize", "route": CustomizeOrderScreen()},
      {"icon": Icons.calendar_today, "label": "Appointments", "route": AppointmentListScreen()},
      {"icon": Icons.shopping_bag, "label": "My Orders", "route": VendorAllOrdersPage()},
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

  Future<List<model.Appointment>> fetchTodaysAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse('http://172.16.6.10:8000/api/appointments/'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      final today = DateTime.now();

      return jsonData.map((item) {
        return model.Appointment.fromJson(item);
      }).where((appointment) {
        // 👇 No need to parse! appointment.date is already a DateTime
        return appointment.date.year == today.year &&
            appointment.date.month == today.month &&
            appointment.date.day == today.day;
      }).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }




  Widget _buildAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentListScreen()));
              },
              child: Text("View All", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        SizedBox(height: 10),
        FutureBuilder<List<model.Appointment>>(
          future: fetchTodaysAppointments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error loading appointments: ${snapshot.error}");
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
                ),
                child: Center(child: Text("No appointments scheduled for today")),
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length > 3 ? 3 : snapshot.data!.length, // Show max 3 appointments
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final appt = snapshot.data![index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.name,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue, size: 20),
                                SizedBox(width: 5),
                                Text(appt.timeSlot, style: TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone, color: Colors.blue, size: 20),
                                SizedBox(width: 5),
                                Text(appt.contact, style: TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }


  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => HomeScreen1()),
          );
        }
        else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewTailoringOrderScreen()),
          );
        }
        else if (index == 2) {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => AppointmentListScreen()),
          );
        }
        else if (index == 3) {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => CreateProfileScreen()),
          );
        }
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}