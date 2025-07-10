import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageToUser = StateProvider<String>((ref) => '');

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final userMessage = ref.watch(messageToUser);

    final text = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.bold);

    final textSmall = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.tertiary);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: height * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Email
            Text(
              'admin7539@walmart.com',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: width * 0.12, vertical: height * 0.017),
              ),
              child: const Text('Manage App Accounts'),
            ),

            SizedBox(height: height * 0.05),

            // Operations card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: () {},
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: EdgeInsets.symmetric(horizontal: width * 0.12, vertical: height * 0.017),
              ),
              child: const Text('Update Logistics'),
            ),
            SizedBox(height: height*0.03,),
            Text(userMessage,style: textSmall?.copyWith(color: Colors.redAccent),),
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
    final file = result.files.first;
    ref.read(messageToUser.notifier).state = '${file.name} has been selected';
  }
}