import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt_process.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'receipts_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipt_processes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptTypeId TEXT NOT NULL,
        imagePaths TEXT NOT NULL,
        dateCreated TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
  }

  // Insert a new receipt process
  Future<int> insertReceiptProcess(ReceiptProcess process) async {
    final db = await database;
    return await db.insert('receipt_processes', process.toMap());
  }

  // Get all receipt processes
  Future<List<ReceiptProcess>> getAllReceiptProcesses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('receipt_processes',
        orderBy: 'dateCreated DESC');

    return List.generate(maps.length, (i) {
      return ReceiptProcess.fromMap(maps[i]);
    });
  }

  // Get processes for a specific receipt type
  Future<List<ReceiptProcess>> getReceiptProcessesByType(String receiptTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_processes',
      where: 'receiptTypeId = ?',
      whereArgs: [receiptTypeId],
      orderBy: 'dateCreated DESC',
    );

    return List.generate(maps.length, (i) {
      return ReceiptProcess.fromMap(maps[i]);
    });
  }

  // Update sync status
  Future<int> updateSyncStatus(int id, bool isSynced) async {
    final db = await database;
    return await db.update(
      'receipt_processes',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a receipt process
  Future<int> deleteReceiptProcess(int id) async {
    final db = await database;
    return await db.delete(
      'receipt_processes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get unsynced processes
  Future<List<ReceiptProcess>> getUnsyncedProcesses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_processes',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return ReceiptProcess.fromMap(maps[i]);
    });
  }
}