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

Future<void> insertOrUpdateKey(String productId, String productName, String key, String newValue, Box<Product> productBox) async {
  final product = productBox.get(productId);
  if (product != null) {
    final productMap = product.toMap(); // Get the map representation
    productMap[key] = newValue; // Update the key with new value
    final updatedProduct = Product.fromMap(productMap);
    await productBox.put(updatedProduct.productId, updatedProduct);
  } else {
    await productBox.put(
      productId,
      Product(productId: productId,productName: productName, price: newValue), // Default key-value pair (price in this case)
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
  Map<String, Uint8List?>? selectedFilesMap;
  List<Map<String, dynamic>>? extractedDataList;
  Map<String, String>? objectNewData = {};
  Map<String, Product> objectData = {};
  bool isLoading = false;

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: true);
      if (result != null) {
        List<Map<String, dynamic>> fileInlineData = [];

        for (var file in result.files) {
          if (file.bytes != null) {
            final fileType = file.name.endsWith('.pdf') ? "application/pdf" : "image/jpeg";
            final base64Data = base64Encode(file.bytes!);
            fileInlineData.add({"inline_data":{"mime_type":fileType,"data":base64Data}});
          }
        }

        setState(() {
          analyzeInvoice(fileInlineData);
        });
      }
    } catch (e) {
      showError('Error picking files: $e');
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

  Future<void> analyzeInvoice(List<Map<String, dynamic>> fileInlineData) async {
    if (fileInlineData.isEmpty) {
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

      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are an expert invoice analyst; Extract and summarize invoice details into a JSON format with fields: productId ( invoice number/policy number), productName, productType (categorized as electronics, fashion, grocery, or others), purchaseDate, price, insuranceDate, insuranceExpiryDate, warrantyStartDate, warrantyEndDate and productDescription ( 3 or 4 words describing the product amd should be different from productName with proper formatting and is mandatory), provide details for all legitimate products except for items like (handling,shipping,promise fees), excluding absent fields, and always calculate and include warrantyEndDate when warrantyStartDate is present, assuming a 1-year warranty if unspecified, and all dates mandatory are required to be in format of DD-MM-YYYY"
              },
              // Use the dynamically passed fileInlineData
              ...fileInlineData
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
          final jsonStart = extractedText.indexOf('[');
          final jsonEnd = extractedText.lastIndexOf(']');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = extractedText.substring(jsonStart, jsonEnd + 1);
            setState(() {
              extractedDataList = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
              // Example: If you want to process the first item in the array
              for(final proObject in extractedDataList!) {
                objectNewData = proObject.map((key, value) => MapEntry(key, value.toString()));
                triggerDetailsScreen(objectNewData!, objectNewData!["productName"]!, widget.productBox, true);
              };
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


void triggerDetailsScreen(Map<String,String> productDetails, String productName, Box<Product> productBox, bool isEditable){
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) =>
        DetailsWidget(details: productDetails,productName: productName,productBox: productBox,isEditable: isEditable)),
  ).then((result){
      setState(() {});
  });
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

  void confirmDelete(String productName, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Product"),
          content: Text("Are you sure you want to delete $productName?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await widget.productBox.delete(productId); // Delete the product
                setState(() {}); // Refresh the UI
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget buildNestedList(dynamic data, {int level = 0}) {
    if (data is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          bool isHovered = false;

          return StatefulBuilder(
            builder: (context, setState) {
              return MouseRegion(
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: Padding(
                  padding: EdgeInsets.all(1.0),
                  child: ListTile(
                    leading: getIcon((entry.value as Product).productType!),
                    title: Text(
                      (entry.value as Product).productName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((entry.value as Product).productDescription ?? ""),
                        Row(
                          children: [
                            Text('Warranty: Active',
                                style: TextStyle(color: Colors.green)),
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                          ],
                        ),
                      ],
                    ),
                    trailing: isHovered
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Details icon
                        IconButton(
                          icon: Icon(Icons.edit_note, color: Colors.white),
                          onPressed: () {
                            triggerDetailsScreen(
                              (entry.value as Product).toMap(),
                              (entry.value as Product).productName!,
                              widget.productBox,
                              true,
                            );
                          },
                          splashRadius: 20,
                          tooltip: "View Details",
                        ),
                        // Delete icon
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            confirmDelete((entry.value as Product).productName!,entry.key);
                          },
                          splashRadius: 20,
                          tooltip: "Delete",
                        ),
                      ],
                    )
                        : SizedBox.shrink(), // Empty space if not hovered
                    onTap: () {
                      triggerDetailsScreen((entry.value as Product).toMap(),
                          (entry.value as Product).productName!, widget.productBox, false);
                    },
                  ),
                ),
              );
            },
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




  Future<bool> _onWillPop() async {
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    objectData = widget.productBox.toMap().cast<String,Product>();
    return WillPopScope(
        onWillPop: _onWillPop,  // Set the callback for system back button
        child: Scaffold(
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
                      onPressed: isLoading ? null : pickFiles,
                      child: Icon(Icons.add),
                    ),
                  ))
                ],
              )
            ],
          )),
    ));
  }
}
