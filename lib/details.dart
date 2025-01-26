import 'package:ai_bill_assistant/product.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting

class DetailsWidget extends StatefulWidget {
  final Map<String, String> details;
  final String productName;
  final Box<Product> productBox;
  final bool isEditable;

  const DetailsWidget({
    super.key,
    required this.details,
    required this.productName, required this.productBox, required this.isEditable
  });

  @override
  State<StatefulWidget> createState() => _DetailsState();
}

class _DetailsState extends State<DetailsWidget> {
  late Map<String, TextEditingController> controllers;
  late TextEditingController productNameController;
  bool isEditable = false;
  late String currProductId;

  final List<String> productTypeOptions = [
    'electronics',
    'fashion',
    'grocery',
    'others'
  ];

  @override
  void initState() {
    super.initState();
    isEditable = widget.isEditable;
    currProductId = widget.details["productId"]!;
    // Initialize TextEditingControllers for each field
    controllers = widget.details.map((key, value) {
      return MapEntry(key, TextEditingController(text: value.toString()));
    });
    // Initialize controller for productName
    productNameController = TextEditingController(text: widget.productName);
  }

  @override
  void dispose() {
    // Dispose of all controllers
    controllers.values.forEach((controller) => controller.dispose());
    productNameController.dispose();
    super.dispose();
  }

  Future<void> insertOrUpdateProduct(Map<String, String> data, Box<Product> productBox) async {
    bool isNewEntry = productBox.get(currProductId) ==  null;
    final product = Product.fromMap(data);
    await productBox.put(currProductId, product); // Use productName as the key
    if(isNewEntry){
      Navigator.pop(context);
    }
  }

  Future<List<String>> getEmptyFieldsByProductId(
      String productId, Box<Product> productBox) async {
    final product = productBox.get(productId);
    if (product == null) return [];

    return product.toMap().entries
        .where((entry) => entry.value == "")
        .map((entry) => entry.key)
        .toList();
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    DateTime initialDate = DateTime.now();
    if (controllers[key]?.text.isNotEmpty == true) {
      try {
        initialDate = DateFormat('dd-MM-yyyy').parse(controllers[key]!.text);
      } catch (_) {}
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controllers[key]?.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  String _toCamelCase(String input) {
    return input.split(RegExp(r'[\s_-]+')).asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value.toLowerCase();
      return index == 0 ? word : '${word[0].toUpperCase()}${word.substring(1)}';
    }).join();
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Bill Buddy';

    widget.details.remove("productName");
    widget.details.remove("productId");
    widget.details.removeWhere((key, value) => value == "");
    widget.details.removeWhere((key, value) => value == "null");

    return MaterialApp(
      title: title,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);  // Pop the current screen from the navigation stack
            },
          ),
          title: const Text(
            'BILL Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 4,
          actions: [
            Padding(padding: EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: isEditable ? Icon(Icons.check_circle, color: Colors.green, size: 30) : Icon(Icons.edit_note, color: Colors.white, size: 30),
              onPressed: () {
                setState(() {
                  isEditable = !isEditable;
                  if (!isEditable) {
                    // Save changes if confirmed
                    for (var key in widget.details.keys) {
                      widget.details[key] = controllers[key]!.text;
                    }
                    widget.details['productName'] = productNameController.text;
                    widget.details['productId'] = currProductId;
                    insertOrUpdateProduct(widget.details, widget.productBox);
                  }
                });
              },
            )),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: isEditable
                  ? TextFormField(
                controller: productNameController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Enter product name",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                ),
              )
                  : Text(
                productNameController.text.toUpperCase(),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.visible,
              ),
            ),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns
                  childAspectRatio: 2, // Adjust aspect ratio as needed
                ),
                children: widget.details.entries.map((entry) {
                  return Card(
                    elevation: 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              entry.key
                                  .replaceAllMapped(
                                RegExp(r'([a-z0-9])([A-Z])'),
                                    (match) =>
                                '${match.group(1)} ${match.group(2)}',
                              )
                                  .toUpperCase()
                                  .replaceAll('_', ' '),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            if (isEditable)
                              entry.key == 'productType'
                                  ? DropdownButton<String>(
                                value: controllers[entry.key]?.text,
                                items: productTypeOptions
                                    .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    controllers[entry.key]?.text =
                                        value ?? '';
                                  });
                                },
                              )
                                  : entry.key.toLowerCase().contains('date')
                                  ? GestureDetector(
                                onTap: () =>
                                    _selectDate(context, entry.key),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller:
                                    controllers[entry.key],
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                              )
                                  : TextFormField(
                                controller: controllers[entry.key],
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: entry.value.toString(),
                                  border: const OutlineInputBorder(),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10),
                                ),
                              )
                            else
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            isEditable? SizedBox() : Align(
                alignment: Alignment.bottomRight,
                child: Padding(padding: EdgeInsets.all(30.0),
                  child: FloatingActionButton(
                    shape: CircleBorder(),
                    onPressed: () async {
                      // Fetch the list of empty fields
                      List<String> emptyFields = await getEmptyFieldsByProductId(currProductId, widget.productBox);

                      if (emptyFields.isEmpty) {
                        // Show a message if there are no empty fields
                        showError("No empty fields available to update.");
                        return;
                      }

                      String? selectedField;
                      String? newValue;

                      // Show the dialog to select a field and enter a value
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Add New Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dropdown for selecting a field
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Select Field',
                                  ),
                                  items: emptyFields.map((field) {
                                    return DropdownMenuItem(
                                      value: field,
                                      child: Text(
                                        field.replaceAllMapped(
                                          RegExp(r'([a-z0-9])([A-Z])'),
                                              (match) => '${match.group(1)} ${match.group(2)}',
                                        ).toUpperCase(),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedField = value;
                                  },
                                ),
                                const SizedBox(height: 10),
                                // Text field for entering a value
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Value',
                                  ),
                                  onChanged: (value) {
                                    newValue = value.trim();
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Add'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );

                      // If a field and value are selected, update the details
                      if (selectedField != null && newValue != null && newValue!.isNotEmpty) {
                        setState(() {
                          widget.details[selectedField!] = newValue!;
                          controllers[selectedField!] = TextEditingController(text: newValue);
                        });

                        // Optionally, save the updated details to the database
                        widget.details['productName'] = productNameController.text;
                        widget.details['productId'] = currProductId;
                        await insertOrUpdateProduct(widget.details, widget.productBox);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Field updated successfully!')),
                        );
                      }
                    },
                    child: Icon(Icons.add),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
