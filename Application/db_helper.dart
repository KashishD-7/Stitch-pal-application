import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  // Function to connect to MySQL Database
  static Future<MySqlConnection> connectDB() async {
    final settings = ConnectionSettings(
      host: '172.20.10.3', // Make sure MySQL allows connections from this IP
      port: 3306,
      user: 'root',      // Default MySQL username
      password: '',      // Leave empty if no password is set
      db: 'stichpal',    // Your database name
    );

    return await MySqlConnection.connect(settings);
  }

  // Function to insert a user into the database
  static Future<Map<String, String>> insertUser(Map<String, dynamic> userData) async {
    try {
      final conn = await connectDB();

      // Insert query
      var result = await conn.query(
        'INSERT INTO users (full_name, email, password, phone_number, dob, gender, user_type, address) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          userData["full_name"],
          userData["email"],
          userData["password"],
          userData["phone_number"],
          userData["dob"],
          userData["gender"],
          userData["user_type"],
          userData["address"],
        ],
      );

      await conn.close();

      if (result.affectedRows! > 0) {
        return {"status": "success", "message": "User registered successfully"};
      } else {
        return {"status": "error", "message": "Failed to insert user"};
      }
    } catch (e) {
      return {"status": "error", "message": "Error: $e"};
    }
  }
}
