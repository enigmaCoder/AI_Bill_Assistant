import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Bill Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
            });
          } else {
            showError('Failed to convert PDF to image.');
          }
        } else {
          setState(() {
            selectedFileBytes = file.bytes;
            selectedFileName = file.name;
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
      final pageImage = await page.render(width: page.width*5, height: page.height*5,format: PdfPageImageFormat.png,backgroundColor: '#FFFFFF',quality: 100);
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
      final apiKey = "AIzaSyCgsPmiy-AMhwfNzc085k7GQcuqIR8dzTE"; // Replace with a secure method to retrieve the API key
      final base64Data = base64Encode(selectedFileBytes!);

      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                "You are an expert invoice analyst; Please extract and summarize all relevant details from the invoice in a structured JSON format, with fields: productName, productDetails (containing purchaseDate, price, insuranceDate, expiryDate, description, sellerInformation, productType, remainingDetails)"
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Data
                }
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
        final extractedText = response.data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (extractedText != null) {
          final jsonStart = extractedText.indexOf('{');
          final jsonEnd = extractedText.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = extractedText.substring(jsonStart, jsonEnd + 1);
            setState(() {
              extractedData = jsonDecode(jsonString);
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

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).toUpperCase().replaceAll('_', ' ');
  }

  Widget buildNestedList(dynamic data, {int level = 0}) {
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(left: level * 16.0),
            child: ExpansionTile(
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
            ),
          );
        }).toList(),
      );
    } else if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((item) => buildNestedList(item, level: level + 1)).toList(),
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
        title: Text('AI Bill Reader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Upload Invoice'),
            ),
            SizedBox(height: 10),
            if (selectedFileBytes != null) Text('Selected File: $selectedFileName'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : analyzeInvoice,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Analyze'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: extractedData != null
                  ? SingleChildScrollView(
                child: buildNestedList(extractedData!),
              )
                  : Center(
                child: Text('Upload an invoice or bill to analyze.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
