// Create DB
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'dart:io';
import 'dart:async';

// Setup Database
Future<Database> initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'product_db.db');

  final exists = await databaseExists(path);

  if (!exists) {
    try {
      ByteData data = await rootBundle.load('assets/db/product_db.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      // fallback: create empty DB
      await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
        CREATE TABLE products (
          product_id INTEGER PRIMARY KEY,
          name TEXT,
          quantity INT,
          unit_price DOUBLE,
          image_path TEXT
        )
      ''');
          if (kDebugMode) {
            print("Empty DB created");
          }
        },
      );
    }
  }

  return openDatabase(path);
}

// Product Adder (Add product details, if exists, replace it) productData : [product_id,name,quanity,unit_price,image_path]
Future<String> productAdder(Database db, productData) async {
  final result = await db.query(
    'products',
    where: 'product_id = ?',
    whereArgs: [productData[0]],
  );

  if (result.isNotEmpty) {
    await db.update(
      'products',
      {
        'product_id': productData[0],
        'name': productData[1],
        'quantity': productData[2],
        'unit_price': productData[3],
        'image_path': productData[4],
      },
      where: 'product_id = ?',
      whereArgs: [productData[0]],
    );
    return 'Product ${productData[0]} updated';
  } else {
    await db.insert('products', {
      'product_id': productData[0],
      'name': productData[1],
      'quantity': productData[2],
      'unit_price': productData[3],
      'image_path': productData[4],
    });
    return 'Product ${productData[0]} added';
  }
}

//Product Delete
Future<void> productDelete(Database db, productID) async {
  await db.delete('products', where: 'product_id = ?', whereArgs: [productID]);
}

// Product Query, returns product details
Future<Map<String, dynamic>> productMapper(Database db, productID) async {

  final result = await db.query(
    'products',
    where: 'product_id = ?',
    whereArgs: [productID],
  );

  if (result.isNotEmpty) {
    return result.first;
  } else {
    return {
      'product_id': productID,
      'name': 'Unknown',
      'quantity': 0,
      'unit_price': 0.00,
      'image_path': 'assets/images/missing_image.png',
    };
  }
}
