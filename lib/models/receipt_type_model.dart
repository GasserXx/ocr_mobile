import 'dart:convert'; // Add this import at the top


class ReceiptType {

  final String receiptTypeId;
  final String name;

  ReceiptType({
    required this.receiptTypeId,
    required this.name,
  });

  factory ReceiptType.fromJson(Map<String, dynamic> json) {
    // Changed from receiptTypeId to id to match backend response
    final id = json['id'];
    if (id == null || id.toString().isEmpty) {
      print('Warning: Received empty or null id from API');
      print('Raw JSON: $json');
    }

    return ReceiptType(
      receiptTypeId: json['id']?.toString() ?? '', // Changed from receiptTypeId to id
      name: utf8.decode(json['name'].toString().codeUnits), // Added UTF-8 decoding for Arabic text
    );
  }

  // Optionally, add a toJson method if you need to send data back to the server
  Map<String, dynamic> toJson() {
    return {
      'id': receiptTypeId, // Note: using 'id' to match backend expectation
      'name': name,
    };
  }
}