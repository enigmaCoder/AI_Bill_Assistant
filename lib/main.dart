import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:pdfx/pdfx.dart';
import 'details.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Buddy',
      theme: ThemeData.dark(),
      home: InvoiceAnalyzer(),
    );
  }
}

class InvoiceAnalyzer extends StatefulWidget {
  @override
  _InvoiceAnalyzerState createState() => _InvoiceAnalyzerState();
}

class _InvoiceAnalyzerState extends State<InvoiceAnalyzer> {
  String? selectedFileName;
  Uint8List? selectedFileBytes;
  Map<String, dynamic>? extractedData;
  Map<String, dynamic>? objectData = {};
  bool isLoading = false;

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;

        // Check if the file is a PDF
        if (file.extension == 'pdf') {
          // Convert PDF to an image
          final imageBytes = await convertPdfToImage(file);
          if (imageBytes != null) {
            setState(() {
              selectedFileBytes = imageBytes.asUnmodifiableView();
              selectedFileName = file.name;
              analyzeInvoice();
            });
          } else {
            showError('Failed to convert PDF to image.');
          }
        } else {
          setState(() {
            selectedFileBytes = file.bytes;
            selectedFileName = file.name;
            analyzeInvoice();
          });
        }
      }
    } catch (e) {
      showError('Error picking file: $e');
    }
  }

  Future<Uint8List?> convertPdfToImage(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        throw Exception('File bytes are null');
      }

      // Open the PDF document
      final pdfDocument = await PdfDocument.openData(file.bytes!);
      final page = await pdfDocument.getPage(pdfDocument.pagesCount);
      final pageImage = await page.render(
          width: page.width * 5,
          height: page.height * 5,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
          quality: 100);
      await page.close();
      Uint8List jpgBytes = pageImage!.bytes;
      return jpgBytes;
    } catch (e) {
      print('Error converting PDF to image: $e');
      return null;
    }
  }

  Future<void> analyzeInvoice() async {
    if (selectedFileBytes == null) {
      showError('No file selected.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final dio = Dio();

    try {
      final apiKey =
          "AIzaSyCgsPmiy-AMhwfNzc085k7GQcuqIR8dzTE"; // Replace with a secure method to retrieve the API key
      final base64Data = base64Encode(selectedFileBytes!);

      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are an expert invoice analyst; Please extract and summarize all relevant details from the invoice in a structured JSON format, with fields: productName, productType (categorized as electronics, fashion, grocery, or others), productDetails (containing purchaseDate, price, insuranceDate, insuranceExpiryDate, warrantyStartDate, warrantyEndDate), and remainingDetails.If warrantyStartDate is present always calculate the warrantyEndDate. Make sure the number of products is always one. Please skip the item from the json which is not present"
              },
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Data}
              }
            ]
          }
        ]
      };

      final response = await dio.post(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final extractedText =
            response.data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (extractedText != null) {
          final jsonStart = extractedText.indexOf('{');
          final jsonEnd = extractedText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = extractedText.substring(jsonStart, jsonEnd + 1);
            setState(() {
              extractedData = jsonDecode(jsonString);
              Map<String, dynamic> extraData = {};
              extraData.addAll(extractedData!.values.toList()[2]);
              extraData.removeWhere((key, value) => value == null);
              objectData?.addAll({
                extractedData!.values.toList()[0]: {
                  extractedData!.values.toList()[1]: extraData
                }
              });
            });
          } else {
            throw Exception('No valid JSON found in response text.');
          }
        } else {
          throw Exception('No valid JSON found in response.');
        }
      } else {
        throw Exception('Failed to analyze invoice: ${response.data}');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Icon getIcon(Map<dynamic, dynamic> productTypeValues) {
    String productName = productTypeValues.keys.toList()[0];
    // Customize the icon based on the productName
    if (productName.toLowerCase().contains('electronics')) {
      return Icon(Icons.devices);
    } else if (productName.toLowerCase().contains('fashion')) {
      return Icon(Icons.checkroom);
    } else if (productName.toLowerCase().contains('grocery')) {
      return Icon(Icons.shopping_basket);
    } else {
      return Icon(Icons.shopping_cart); // Default icon
    }
  }

void triggerDetailsScreen(Map<dynamic,dynamic> productTypeValues, String productName){
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) =>
        DetailsWidget(details: productTypeValues.values.toList()[0],productName: productName)),
  );
}

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
          return '${match.group(1)} ${match.group(2)}';
        })
        .toUpperCase()
        .replaceAll('_', ' ');
  }

  Widget buildNestedList(dynamic data, {int level = 0}) {
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {triggerDetailsScreen(entry.value,entry.key);},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  // Add this
                  borderRadius:
                      BorderRadius.circular(5.0), // For perfectly sharp corners
                ),
              ),
              icon: getIcon(entry.value), // The icon
              label: Row(
                // Use a Row
                children: [
                  // Icon is already part of ElevatedButton.icon, so don't add it here
                  SizedBox(width: 8), // Optional spacing between icon and text
                  Expanded(
                    // Ensure text takes remaining space and wraps if needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatKey(entry.key),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                        ),


                      ],
                    ),
                  ),
                ],
              ),
            )
            /*ExpansionTile(
              title: Text(
                formatKey(entry.key),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0 - level * 1.0,
                  color: Colors.blueAccent.shade700,
                ),
              ),
              children: [
                buildNestedList(entry.value, level: level + 1),
              ],
            )*/,
          );
        }).toList(),
      );
    } else if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data
            .map((item) => buildNestedList(item, level: level + 1))
            .toList(),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: level * 16.0, top: 4.0, bottom: 4.0),
        child: Text(
          data?.toString() ?? 'null',
          style: TextStyle(
            fontSize: 14.0 - level * 0.5,
            color: Colors.grey.shade800,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Buddy'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            alignment: Alignment(0, 0),
            children: [
              Stack(
                children: [
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Opacity(opacity: 1)]),
                  isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : SizedBox(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Background color
                      foregroundColor: Colors.white, // Text and icon color
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12), // Adjust padding
                      textStyle: TextStyle(fontSize: 16), // Text size
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    icon: Icon(Icons.upload_file, color: Colors.white), // Choose an appropriate icon
                    label:
                        isLoading ? Text('Analyzing...') : Text('Upload Bill'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () {},
                      child: Text('Founder ka button')),
                  SizedBox(height: 20),
                  Expanded(
                    child: objectData != null
                        ? SingleChildScrollView(
                            child: buildNestedList(objectData!),
                          )
                        : Center(
                            child:
                                Text('Upload an invoice or bill to analyze.'),
                          ),
                  ),
                ],
              )
            ],
          )),
    );
  }
}
