class ReceiptProcess {
  final int? id; // local DB id
  final String receiptTypeId;
  final List<String> imagePaths;
  final DateTime dateCreated;
  final bool isSynced; // to track if sent to backend

  ReceiptProcess({
    this.id,
    required this.receiptTypeId,
    required this.imagePaths,
    required this.dateCreated,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptTypeId': receiptTypeId,
      'imagePaths': imagePaths.join(','), // Store paths as comma-separated string
      'dateCreated': dateCreated.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ReceiptProcess.fromMap(Map<String, dynamic> map) {
    return ReceiptProcess(
      id: map['id'],
      receiptTypeId: map['receiptTypeId'],
      imagePaths: (map['imagePaths'] as String).split(','),
      dateCreated: DateTime.parse(map['dateCreated']),
      isSynced: map['isSynced'] == 1,
    );
  }
}