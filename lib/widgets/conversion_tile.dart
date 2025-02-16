import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pixelsheet/models/conversion_item.dart';

class ConversionTile extends StatelessWidget {
  final ConversionItem item;
  final VoidCallback onExport;

  const ConversionTile({super.key, required this.item, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image Path: ${item.imagePath}'),
            Text('Extracted Text: ${item.extractedText}'),
            Text(
                'Timestamp: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)}'),
            ElevatedButton(
              onPressed: onExport,
              child: const Text('Export to CSV'),
            ),
          ],
        ),
      ),
    );
  }
}