// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import './db_handler.dart';

final predictionRefreshTrigger = StateProvider<int>((ref) => 0);


final messageToUser = StateProvider<String>((ref) => '');
dynamic file;
int fileLength = 0;

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final userMessage = ref.watch(messageToUser);

    final text = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSecondary,
      fontWeight: FontWeight.bold,
    );

    final textSmall = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.tertiary,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.08,
          vertical: height * 0.05,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Email
            Text(
              'admin7539@shop.com',
              style: textSmall,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: height * 0.01),

            // Profile Icon
            Icon(
              Icons.account_circle_sharp,
              size: height * 0.1,
              color: Theme.of(context).colorScheme.tertiary,
            ),

            SizedBox(height: height * 0.01),

            // Greeting
            Text('Hello, Admin7539', style: text),

            SizedBox(height: height * 0.01),

            // Manage App Accounts button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                elevation: 2,
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.12,
                  vertical: height * 0.017,
                ),
              ),
              child: const Text('Manage App Accounts'),
            ),

            SizedBox(height: height * 0.05),

            // Operations card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: height * 0.02),
                child: Column(
                  children: [
                    Text('OPERATIONS:', style: text),
                    const Divider(thickness: 1),
                    TextButton(
                      onPressed: () {
                        pickFile(ref);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      ),
                      child: Text('Update Delivery Data', style: textSmall),
                    ),
                    const Divider(thickness: 1),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      ),
                      child: Text('Update Supply Data', style: textSmall),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: height * 0.035),

            // Update Logistics Button
            TextButton(
              onPressed: () {
                if (fileLength != 0) {
                  predictionRunner(ref, file);
                } else {
                  ref.read(messageToUser.notifier).state =
                      'Please select a file';
                }
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.12,
                  vertical: height * 0.017,
                ),
              ),
              child: const Text('Update Logistics'),
            ),
            SizedBox(height: height * 0.03),
            Text(
              userMessage,
              style: textSmall?.copyWith(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> pickFile(WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result != null && result.files.isNotEmpty) {
    file = result.files.first;
    fileLength = await File(file.path!).length();
    ref.read(messageToUser.notifier).state = '${file.name} has been selected';
  }
}

Future<void> predictionRunner(WidgetRef ref, PlatformFile file) async {
  ref.read(messageToUser.notifier).state = 'Prediction running, please wait';

  final uri = Uri.parse('http://10.0.2.2:8000/predict');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(await http.MultipartFile.fromPath('file', file.path!));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    ref.read(messageToUser.notifier).state =
        'Prediction successful, downloading...';
    await predictionDownloader(ref);
  } else {
    ref.read(messageToUser.notifier).state = 'Prediction failed';
  }
}

Future<void> predictionDownloader(WidgetRef ref) async {
  final response = await http.get(Uri.parse('http://10.0.2.2:8000/download'));
  if (response.statusCode == 200) {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/predictions.csv';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    await dbUpdater(ref, file);

    ref.read(messageToUser.notifier).state = 'DB Updated';
  } else {
    ref.read(messageToUser.notifier).state = 'Could not download predictions';
  }
}


Future<void> dbUpdater(WidgetRef ref, File file) async {
  try {
    await DBHandler.parseCSVAndInsert(file);
    ref.read(messageToUser.notifier).state = 'DB Updated';
    ref.read(predictionRefreshTrigger.notifier).state++;
  } catch (e) {
    ref.read(messageToUser.notifier).state = 'DB update error: $e';
    if (kDebugMode) print('❌ DB update error: $e');
  }
}

// Run backend locally with: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
