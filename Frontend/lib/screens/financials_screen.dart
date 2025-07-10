import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:walmart_inventory_management_system/screens/account_screen.dart';
import '../services/product_db_manager.dart';
import 'package:walmart_inventory_management_system/screens/db_handler.dart';

class FinancialsPage extends ConsumerStatefulWidget {
  const FinancialsPage({super.key});

  @override
  ConsumerState<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends ConsumerState<FinancialsPage> {
  late Future<List<Prediction>> predictionsFuture;
  late Future<Database> productDBFuture;
  late List<String> weekDays;

  @override
  void initState() {
    super.initState();

    productDBFuture = initDatabase();
    final today = DateTime.now();
    weekDays = List.generate(
      7,
      (i) => DateFormat('EEEE').format(today.add(Duration(days: i))),
    );
  }

  Future<double> calculateTotalEarningsForDay(
    List<Prediction> daily,
    Database productDB,
  ) async {
    double totalForDay = 0.0;

    final hourly = <int, List<Prediction>>{};
    for (var p in daily) {
      hourly.putIfAbsent(p.hour, () => []).add(p);
    }

    for (var hour in hourly.keys) {
      final top3 =
          (hourly[hour]!..sort((a, b) => b.confidence.compareTo(a.confidence)))
              .take(3);
      for (var p in top3) {
        final product = await productMapper(productDB, p.productId);
        final price = product['unit_price'] ?? 0.0;
        totalForDay += price * p.predictedQuantity;
      }
    }

    return totalForDay;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(predictionRefreshTrigger);
    predictionsFuture = DBHandler.getAllPredictions();

    return FutureBuilder(
      future: Future.wait([predictionsFuture, productDBFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Prediction> predictions = snapshot.data![0];
        final Database productDB = snapshot.data![1];

        return FutureBuilder(
          future: Future.wait(
            weekDays.map((day) async {
              final daily = predictions.where((p) => p.day == day).toList();
              final total = await calculateTotalEarningsForDay(
                daily,
                productDB,
              );
              return {'day': day, 'total': total};
            }).toList(),
          ),
          builder:
              (context, AsyncSnapshot<List<Map<String, dynamic>>> totalsSnap) {
                if (!totalsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totals = totalsSnap.data!;
                final weekTotal = totals.fold(
                  0.0,
                  (sum, e) => sum + e['total'],
                );

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Week'
                        's Total:',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                      Text(
                        "\$${weekTotal.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 20),
                      ...totals.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e['day'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "\$${(e['total'] as double).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        );
      },
    );
  }
}
