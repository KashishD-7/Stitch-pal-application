class Appointment {
  final int id;
  final DateTime date;
  final String timeSlot;
  final String name;
  final String contact;
  final String? remark;
  final DateTime createdAt;
  final int? vendorId;
  final String? vendorName;

  Appointment({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.name,
    required this.contact,
    this.remark,
    required this.createdAt,
    this.vendorId,
    this.vendorName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      date: DateTime.parse(json['date']),
      timeSlot: json['time_slot'],
      name: json['name'],
      contact: json['contact'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['created_at']),
      vendorId: json['vendor'] ?? json['vendor_id'],
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
    );
  }
}