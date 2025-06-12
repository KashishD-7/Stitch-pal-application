import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'forgotpass.dart';
import 'login.dart';
import 'profile.dart';
import 'register.dart';
import 't&c.dart';
import 'home.dart';
import 'order.dart';
import 'measurement.dart';
import 'namesize.dart';
import 'shopelocation.dart';
import 'ordercustomizev.dart';
import 'appointment.dart';
import 'stitching.dart';
import 'homev.dart';
import 'orderv.dart';
import 'shopelocationv.dart';
import 'show_appointments.dart';
import 'ordercustomize.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCBLazfo4GE3eTvZUf-y7iarZpe6R7jIKg",
      authDomain: "stichpal.firebaseapp.com",
      projectId: "stichpal",
      storageBucket: "stichpal.firebasestorage.app",
      messagingSenderId: "G-ERE007JZHP",
      appId: "1:1070679471312:web:c8a854f0d41af1fd849ad5",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stich Pal',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/register',
      routes: {
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginPage(),
        '/forgotpass': (context) => ForgotPasswordScreen(),
        '/profile': (context) => CreateProfileScreen(),
        '/t&c': (context) => TermsAndConditionsScreen(),
        '/home': (context) => HomeScreen(),
        '/order': (context) => OrderHistoryScreen(),
        '/measurement': (context) => MeasurementStorageScreen(),
        '/namesize': (context) => CustomerDetailsPage(),
        '/shoplocation': (context) => ShopDetailsScreen(),
        '/ordercustomizev': (context) => CustomizeOrderScreen(),
        '/appointment': (context) => AppointmentScreen(),
        '/stitching': (context) => StitchingMethodsScreen(),
        '/homev': (context) => HomeScreen1(),
        '/orderv': (context) => NewTailoringOrderScreen(),
        '/shopelocationv': (context) => ShopDetailsScreen1(),
        '/show_appointments': (context) => AppointmentListScreen(),
        '/ordercustomize': (context) => CustomizeOrderScreen1(),
      },
    );
  }
}
