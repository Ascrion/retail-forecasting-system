import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import 'db_handler.dart';
import '../services/product_db_manager.dart';
import './account_screen.dart';

class WeekPage extends ConsumerStatefulWidget {
  const WeekPage({super.key});

  @override
  ConsumerState<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends ConsumerState<WeekPage> {
  late Future<List<Prediction>> predictionsFuture;
  late Future<Database> productDBFuture;
  late List<String> weekDays;
  late String todayName;

  @override
  void initState() {
    super.initState();
    productDBFuture = initDatabase();
    final today = DateTime.now();
    todayName = DateFormat('EEEE').format(today);
    weekDays = List.generate(7, (i) => DateFormat('EEEE').format(today.add(Duration(days: i))));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(predictionRefreshTrigger); 
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.2;
    final cardHeight = screenHeight * 0.15;
    final predictionsFuture = DBHandler.getAllPredictions();

    return FutureBuilder(
      future: Future.wait([predictionsFuture, productDBFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Prediction> predictions = snapshot.data![0];
        final Database productDB = snapshot.data![1];

        return ListView.builder(
          itemCount: 7,
          padding: const EdgeInsets.only(bottom: 16),
          itemBuilder: (context, index) {
            final day = weekDays[index];
            final daily = predictions.where((p) => p.day == day).toList();

            if (daily.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text("📭 No data for $day",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              );
            }

            final groupedByHour = <int, Prediction>{};
            for (var p in daily) {
              if (!groupedByHour.containsKey(p.hour) ||
                  p.confidence > groupedByHour[p.hour]!.confidence) {
                groupedByHour[p.hour] = p;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Divider(color: Theme.of(context).colorScheme.tertiary,height: 1,),
                // Day Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(10,20,5,5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: day == todayName
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                        ),
                      ),
                      if (day == todayName)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Today",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Horizontal Card List
                SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupedByHour.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final hour = groupedByHour.keys.elementAt(i);
                      final prediction = groupedByHour[hour]!;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: productMapper(productDB, prediction.productId),
                        builder: (context, snap) {
                          final prod = snap.data ??
                              {
                                'name': 'Unknown',
                                'image_path': 'assets/images/missing_image.png'
                              };

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              width: cardWidth,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 91, 90, 90).withAlpha(100),
                                    blurRadius: 20,
                                     spreadRadius: 1,
                                     offset: Offset(0, 0)
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${hour.toString().padLeft(2, '0')}:00",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        prod['image_path'],
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prod['name'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
