import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
  PlatformFile? selectedFile;
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
              selectedFile = PlatformFile(
                name: file.name,
                bytes: imageBytes!,
                size: imageBytes.length,
              );
            });
          } else {
            showError('Failed to convert PDF to image.');
          }
        } else {
          setState(() {
            selectedFile = file;
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
      final page = await pdfDocument.getPage(1);
      final pageImage = await page.render(width: page.width, height: page.height);
      await page.close();
      Uint8List jpgBytes = pageImage!.bytes;
      final base64Image = base64Encode(jpgBytes);
      return jpgBytes;
    } catch (e) {
      print('Error converting PDF to image: $e');
      return null;
    }
  }

  Future<void> analyzeInvoice() async {
    if (selectedFile == null) {
      showError('No file selected.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final apiKey = "AIzaSyCgsPmiy-AMhwfNzc085k7GQcuqIR8dzTE"; // Replace with your Google API key
      final base64Data = base64Encode(selectedFile!.bytes!);

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey");

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                "You are an expert invoice analyst; extract and summarize all relevant details from the invoice, and present this in a structured JSON format."
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

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          extractedData = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to analyze invoice: ${response.body}');
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

  Widget displayExtractedData() {
    if (extractedData == null) return Text('No data available.');

    return ListView(
      shrinkWrap: true,
      children: extractedData!.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          subtitle: Text(entry.value.toString()),
        );
      }).toList(),
    );
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
            if (selectedFile != null) Text('Selected File: ${selectedFile!.name}'),
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
                  ? displayExtractedData()
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
