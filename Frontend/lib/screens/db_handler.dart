import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart';

// 📦 Prediction Model
class Prediction {
  final int? id;
  final int hour;
  final String day;
  final String productId;
  final double confidence;
  final int predictedQuantity;
  final String predictedArea;

  Prediction({
    this.id,
    required this.hour,
    required this.day,
    required this.productId,
    required this.confidence,
    required this.predictedQuantity,
    required this.predictedArea,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'hour': hour,
    'day': day,
    'productId': productId,
    'confidence': confidence,
    'predictedQuantity': predictedQuantity,
    'predictedArea': predictedArea,
  };

  static Prediction fromMap(Map<String, dynamic> map) => Prediction(
    id: map['id'],
    hour: map['hour'],
    day: map['day'],
    productId: map['productId'],
    confidence: map['confidence'],
    predictedQuantity: map['predictedQuantity'],
    predictedArea: map['predictedArea'],
  );
}

// 🧠 DB Handler
class DBHandler {
  static Database? _db;

  // Get DB instance
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Initialize DB
  static Future<Database> _initDb() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'predictions.db');
    print('📦 DB Path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hour INTEGER,
            day TEXT,
            productId TEXT,
            confidence REAL,
            predictedQuantity INTEGER,
            predictedArea TEXT
          )
        ''');
      },
    );
  }

  // Insert one prediction
  static Future<void> insertPrediction(Prediction p) async {
    final db = await database;
    await db.insert('predictions', p.toMap());
    //if (kDebugMode) print("✅ Inserted: ${p.productId} at ${p.day} ${p.hour}");
  }

  // Get all predictions
  static Future<List<Prediction>> getAllPredictions() async {
    final db = await database;
    final maps = await db.query('predictions');
    print("📊 Retrieved ${maps.length} predictions");
    return maps.map((e) => Prediction.fromMap(e)).toList();
  }

  // Delete all predictions
  static Future<void> deleteAll() async {
    final db = await database;
    await db.delete('predictions');
    if (kDebugMode) print("🗑️ All predictions deleted");
  }

  // Parse CSV and insert into DB
// Parse CSV and insert into DB
static Future<void> parseCSVAndInsert(File csvFile) async {
  final raw = await csvFile.readAsString();
  final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(raw);

  if (rows.isEmpty || rows.length < 2) {
    if (kDebugMode) print('⚠️ CSV has no valid data rows');
    return;
  }

  final headers = rows[0].sublist(1); // Skip the first empty cell (Hour column)
  final data = rows.sublist(1);       // Skip header row

  print('📄 Headers: $headers');
  print('🧾 First Data Row: ${data.first}');

  await deleteAll();

  for (var i = 0; i < data.length; i++) {
    final row = data[i];

    final hourRaw = row[0].toString().trim();
    if (hourRaw.isEmpty) {
      print("⛔ Skipping row $i: Missing hour");
      continue;
    }

    final hour = int.tryParse(hourRaw);
    if (hour == null) {
      print("⛔ Skipping row $i: Invalid hour format ($hourRaw)");
      continue;
    }

    for (var j = 1; j < row.length; j++) {
      final day = headers[j - 1];
      final cell = row[j];

      if (cell == null || cell.toString().trim().isEmpty) continue;

      try {
        final jsonList = jsonDecode(cell.toString());
        if (jsonList is! List) {
          print("⚠️ Skipping invalid JSON at $hour - $day: Not a list");
          continue;
        }

        for (final item in jsonList) {
          final prediction = Prediction(
            hour: hour,
            day: day,
            productId: item['product_id'].toString(),
            confidence: double.tryParse(item['confidence'].toString()) ?? 0.0,
            predictedQuantity: int.tryParse(item['predicted_quantity'].toString()) ?? 0,
            predictedArea: item['predicted_area'].toString(),
          );
          await insertPrediction(prediction);
        }
      } catch (e) {
        print('⚠️ JSON error at $hour - $day: $e');
      }
    }
  }

  print('✅ CSV inserted into DB');
}


}
