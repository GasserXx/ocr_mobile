class ReceiptType {
  final String receiptTypeId;
  final String name;

  ReceiptType({
    required this.receiptTypeId,
    required this.name,
  });

  factory ReceiptType.fromJson(Map<String, dynamic> json) {
    final id = json['receiptTypeId'];
    if (id == null || id.toString().isEmpty) {
      print('Warning: Received empty or null receiptTypeId from API');
      print('Raw JSON: $json');
    }

    return ReceiptType(
      receiptTypeId: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}