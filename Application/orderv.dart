import 'dart:typed_data';
import 'dart:io' as io; // For mobile
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewTailoringOrderScreen extends StatefulWidget {
  @override
  _NewTailoringOrderScreenState createState() => _NewTailoringOrderScreenState();
}

class _NewTailoringOrderScreenState extends State<NewTailoringOrderScreen> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  XFile? _orderImage;
  Uint8List? _orderImageBytes;

  List<String> selectedGarmentTypes = [];
  List<String> garmentTypes = ['Shirt', 'Pant', 'Suit', 'Dress', 'Blouse', 'Jeans', 'Jacket'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _orderImage = image;
        _orderImageBytes = bytes;
      });
    }
  }

  void _validateAndSubmit() async {
    if (_customerNameController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _priceController.text.isEmpty ||
        selectedGarmentTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You need to log in first!')));
      return;
    }

    var url = Uri.parse("http://172.16.6.10:8000/api/create-order/");
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['customer_name'] = _customerNameController.text;
    request.fields['contact_number'] = _contactNumberController.text;
    request.fields['clothing_types'] = selectedGarmentTypes.join(",");
    request.fields['additional_instructions'] = _instructionsController.text;
    request.fields['price'] = _priceController.text;

    try {
      if (_orderImage != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'order_photo',
            _orderImageBytes!,
            filename: _orderImage!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'order_photo',
            _orderImage!.path,
          ));
        }
      }

      print("Sending request...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print("Response: $responseData");

      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 201) {
        // Clear form
        setState(() {
          _customerNameController.clear();
          _contactNumberController.clear();
          _instructionsController.clear();
          _priceController.clear();
          selectedGarmentTypes.clear();
          _orderImage = null;
          _orderImageBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order placed successfully!")));

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${jsonResponse.toString()}")));
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Tailoring Order'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('Customer Name', _customerNameController, isRequired: true),
            _buildTextField('Contact Number', _contactNumberController, isRequired: true, isNumber: true),
            _buildGarmentTypeSelection(),
            _buildImagePicker(),
            _buildTextField('Additional Instructions', _instructionsController, maxLines: 3),
            _buildTextField('Price', _priceController, isRequired: true, isNumber: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateAndSubmit,
              child: Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildGarmentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Type of Clothe *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (selectedGarmentTypes.isEmpty)
          Text('This field is required', style: TextStyle(color: Colors.red)),
        ...garmentTypes.map((type) {
          return CheckboxListTile(
            title: Text(type),
            value: selectedGarmentTypes.contains(type),
            onChanged: (bool? selected) {
              setState(() {
                selected == true
                    ? selectedGarmentTypes.add(type)
                    : selectedGarmentTypes.remove(type);
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Order Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        IconButton(
          icon: Icon(Icons.camera_alt, size: 40),
          onPressed: _pickImage,
        ),
        if (_orderImageBytes != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Image.memory(_orderImageBytes!, height: 100, width: 100),
          ),
      ],
    );
  }
}
