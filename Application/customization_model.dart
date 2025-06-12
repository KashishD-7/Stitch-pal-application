class OrderCustomization {
  final int id;
  final String? orderName; // should match 'order_name' in JSON
  final String? fabricChoice;
  final String? stylePreferences;
  final String? colorOptions;
  final String? additionalDetails;
  final String? createdAt;

  OrderCustomization({
    required this.id,
    this.orderName,
    this.fabricChoice,
    this.stylePreferences,
    this.colorOptions,
    this.additionalDetails,
    this.createdAt,
  });

  factory OrderCustomization.fromJson(Map<String, dynamic> json) {
    return OrderCustomization(
      id: json['id'],
      orderName: json['order_name'], // Ensure this matches the serialized key
      fabricChoice: json['fabric_choice'],
      stylePreferences: json['style_preferences'],
      colorOptions: json['color_options'],
      additionalDetails: json['additional_details'],
      createdAt: json['created_at'],
    );
  }
}
