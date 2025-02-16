import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pixelsheet/models/conversion_item.dart';
import 'package:pixelsheet/screens/table_display_page.dart';
import 'package:pixelsheet/widgets/custom_app_bar.dart';
import 'package:pixelsheet/providers/providers.dart';
import 'dart:io';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with SingleTickerProviderStateMixin {
  late Future<List<ConversionItem>> _historyItems;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  Future<void> _exportToCsv(BuildContext context, ConversionItem item) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'table_data_$timestamp';
      final Uint8List bytes = Uint8List.fromList(item.extractedText.codeUnits);

      final String? savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (savedPath != null) {
        _showSnackBar('CSV file saved successfully to: $savedPath');
      } else {
        _showSnackBar('Save operation canceled.');
      }
    } catch (e, st) {
      print('Error saving CSV: $e\n$st');
      _showSnackBar('Error saving CSV: $e');
    }
  }

  Future<void> _exportToFile(BuildContext context, ConversionItem item) async {
    if (item.extractedText.isEmpty || item.extractedText == "Error") {
      _showSnackBar('No text to export.');
      return;
    }

    try {
      final String rawText = item.extractedText;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'extracted_text_$timestamp';

      // Convert text to UTF-8 bytes
      final Uint8List bytes = Uint8List.fromList(rawText.codeUnits);

      // Save the file using FileSaver's saveAs() to trigger the system picker
      final String? savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: 'txt',
        mimeType: MimeType.text,
      );

      if (savedPath != null) {
        _showSnackBar('File saved successfully to: $savedPath');
      } else {
        _showSnackBar('Save operation canceled.');
      }
    } catch (e, st) {
      print('Error saving file: $e\n$st');
      _showSnackBar('Error saving file: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
     try{
         final databaseService = ref.read(databaseServiceProvider);
         _historyItems = databaseService.getConversions();
     } catch(e, st){
       print('Error Loading history : $e\n$st');
       _showSnackBar('Error loading conversion history.');
     }
  }

  void _showImageDialog(String imagePath) {
     if(!mounted || _scaffoldKey.currentContext == null) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                    const Text('Close', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Future<void> _deleteConversion(ConversionItem item) async {
    final databaseService = ref.read(databaseServiceProvider);
    try {
      await databaseService.deleteConversion(item.id!);
       setState(() {
        _loadHistory();
      });
        _showSnackBar('Conversion deleted!');
    } catch (e, st) {
      print('Error during conversion deletion : $e\n$st');
      _showSnackBar('Error during deletion: $e');
    }
  }

  void _showSnackBar(String message) {
    if (_scaffoldKey.currentContext == null || !mounted) return;
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(message),
        backgroundColor: Colors.blue.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: const CustomAppBar(title: 'Conversion History'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // Colors.pinkAccent,
              Colors.white70,
              Colors.white70,
              Colors.blue.shade500,
              Colors.purple.shade500
            ],
          ),
        ),
        child: FutureBuilder<List<ConversionItem>>(
          future: _historyItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.blue),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,
                        size: 64, color: Colors.blue.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversion history available.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      ConversionItem item = snapshot.data![index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.deepPurple.shade50,
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TableDisplayPage(
                                          parsedData: [item.extractedText],
                                          images: [XFile(item.imagePath)],
                                        ),
                                      ),
                                    );
                                  } catch (e, st){
                                      print('Navigation error : $e\n$st');
                                      _showSnackBar('Error navigating to table please restart and try again.');
                                   }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _showImageDialog(item.imagePath),
                                            child: Hero(
                                              tag:
                                                  'image_${item.id}', // Retain the Hero only for the image
                                              child: Container(
                                                height: 80,
                                                width: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.file(
                                                    File(item.imagePath),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  DateFormat('MMM dd, yyyy HH:mm')
                                                      .format(item.timestamp),
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  item.instruction,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.extractedText,
                                          style: const TextStyle(
                                              color: Colors.black87),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.save_alt),
                                            color: Colors.blue[700],
                                            onPressed: () {
                                                if(item.type == "md"){
                                                 _exportToFile(context, item);
                                                 } else {
                                                  _exportToCsv(context, item);
                                               }
                                            }
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red[400],
                                            onPressed: () =>
                                                _deleteConversion(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              );
            }
          },
        ),
      ),
    );
  }
}