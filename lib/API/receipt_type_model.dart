// receipt_type_model.dart
class ReceiptType {
  final String name;

  ReceiptType({
    required this.name,
  });

  factory ReceiptType.fromJson(String name) {
    return ReceiptType(name: name);
  }
}