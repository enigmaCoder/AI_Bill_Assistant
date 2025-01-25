import 'dart:convert';
import 'dart:typed_data';
import 'package:ai_bill_assistant/product.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pdfx/pdfx.dart';
import 'details.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  await Hive.openBox<Product>('products');
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

Future<void> insertOrUpdateProduct(Map<String, String> data, Box<Product> productBox) async {
  final product = Product.fromMap(data);
  await productBox.put(product.productName, product); // Use productName as the key
}

Future<void> insertOrUpdateKey(String productName, String key, String newValue, Box<Product> productBox) async {
  final product = productBox.get(productName);
  if (product != null) {
    final productMap = product.toMap(); // Get the map representation
    productMap[key] = newValue; // Update the key with new value
    final updatedProduct = Product.fromMap(productMap);
    await productBox.put(updatedProduct.productName, updatedProduct);
  } else {
    await productBox.put(
      productName,
      Product(productName: productName, price: newValue), // Default key-value pair (price in this case)
    );
  }
}

Future<String?> getFieldByProductName(String productName, String key,Box<Product> productBox) async {
  final product = productBox.get(productName);
  return product?.toMap()[key];
}


class InvoiceAnalyzer extends StatefulWidget {
  final Box<Product> productBox = Hive.box<Product>('products');
  @override
  _InvoiceAnalyzerState createState() => _InvoiceAnalyzerState();
}

class _InvoiceAnalyzerState extends State<InvoiceAnalyzer> {
  String? selectedFileName;
  Uint8List? selectedFileBytes;
  Map<String, dynamic>? extractedData;
  Map<String, String>? objectNewData = {};
  Map<String, Product> objectData = {};
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
                    "You are an expert invoice analyst; Extract and summarize invoice details into a JSON format with fields: productName, productType (categorized as electronics, fashion, grocery, or others), purchaseDate, price, insuranceDate, insuranceExpiryDate, warrantyStartDate, warrantyEndDate and productDescription ( 3 or 4 words describing the product amd should be different from productName with proper formatting), ensuring only one product is included, excluding absent fields, and always calculate and include warrantyEndDate when warrantyStartDate is present, assuming a 1-year warranty if unspecified"
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
              objectNewData = extractedData!.map((key, value) => MapEntry(key, value.toString()));
              insertOrUpdateProduct(objectNewData!, widget.productBox);
              objectData = widget.productBox.toMap().cast<String,Product>();
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

  Icon getIcon(String productType) {
    // Customize the icon based on the productName
    if (productType.toLowerCase().contains('electronics')) {
      return Icon(Icons.devices);
    } else if (productType.toLowerCase().contains('fashion')) {
      return Icon(Icons.checkroom);
    } else if (productType.toLowerCase().contains('grocery')) {
      return Icon(Icons.shopping_basket);
    } else {
      return Icon(Icons.shopping_cart); // Default icon
    }
  }


void triggerDetailsScreen(Map<String,dynamic> productDetails, String productName){
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) =>
        DetailsWidget(details: productDetails,productName: productName)),
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
            padding: EdgeInsets.all(1.0),
            child: ListTile(
              leading: getIcon((entry.value as Product).productType!),
              title: Text(
                  entry.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis
              ),
              //subtitle: Text(getProductDescription(entry.value)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((entry.value as Product).productDescription!),
                  Row(
                    children: [
                      Text('Warranty: Active', style: TextStyle(color: Colors.green)),
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ],
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                triggerDetailsScreen((entry.value as Product).toMap(),entry.key);
              },
            )

            /*child: ElevatedButton.icon(
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
            )*/
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
    objectData = widget.productBox.toMap().cast<String,Product>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'BILL Buddy',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ), // Background color
        centerTitle: true, // Center the title
        elevation: 4, // Shadow effect
        leading: Icon(Icons.menu),
      ),
      body: Padding(
          padding: const EdgeInsets.only(top: 46.0),
          child: Stack(
            alignment: Alignment(0, 0),
            children: [
              Stack(
                children: [
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Opacity(opacity: 1)]),
                  isLoading
                      ? CircularProgressIndicator(color: Colors.purpleAccent.shade100)
                      : SizedBox(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                            child: buildNestedList(objectData),
                          ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(padding: EdgeInsets.all(30.0),
                      child: FloatingActionButton(
                        shape: CircleBorder(),
                      onPressed: isLoading ? null : pickFile,
                      child: Icon(Icons.add),
                    ),
                  ))
                ],
              )
            ],
          )),
    );
  }
}
