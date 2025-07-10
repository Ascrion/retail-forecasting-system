import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:walmart_inventory_management_system/screens/account_screen.dart';
import 'db_handler.dart';

class DayPage extends ConsumerWidget {
  const DayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(predictionRefreshTrigger); 
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now);
    final todayDate = DateFormat('MMMM d, y').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$todayName, $todayDate',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Prediction>>(
            future: DBHandler.getAllPredictions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('❌ Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('📭 No data found', style: TextStyle(color: Colors.black)));
              }

              final predictions = snapshot.data!;
              final todayPredictions = predictions.where((p) => p.day == todayName).toList();

              if (todayPredictions.isEmpty) {
                return Center(child: Text('📭 No predictions for $todayName', style: const TextStyle(color: Colors.black)));
              }

              // Group predictions by hour
              final groupedByHour = <int, List<Prediction>>{};
              for (final p in todayPredictions) {
                groupedByHour.putIfAbsent(p.hour, () => []).add(p);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: groupedByHour.keys.length,
                separatorBuilder: (_, __) => const Divider(thickness: 2),
                itemBuilder: (context, index) {
                  final hour = groupedByHour.keys.elementAt(index);
                  final hourPredictions = groupedByHour[hour]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Time $hour:00',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          dataTextStyle: const TextStyle(color: Colors.black),
                          columns: const [
                            DataColumn(label: Text('Product ID')),
                            DataColumn(label: Text('Confidence')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Area')),
                          ],
                          rows: hourPredictions.map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p.productId)),
                              DataCell(Text(p.confidence.toStringAsFixed(2))),
                              DataCell(Text(p.predictedQuantity.toString())),
                              DataCell(Text(p.predictedArea)),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
