import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailsWidget extends StatefulWidget {
  final Map<String, dynamic> details;
  final String productName;// Add this line

  const DetailsWidget({super.key, required this.details, required this.productName}); // Update constructor

  @override
  State<StatefulWidget> createState() => _DetailsState();
}

class _DetailsState extends State<DetailsWidget> {
  @override
  Widget build(BuildContext context) {
    const title = 'Bill Buddy';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: Column(
          children: [
        Padding(
        padding: const EdgeInsets.all(10.0),
          child:Text(
          widget.productName.toUpperCase(),
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          overflow: TextOverflow.visible,
        )),
        Expanded(
            child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            childAspectRatio: 2, // Adjust aspect ratio as needed
          ),
          children: widget.details.entries.map((entry) {
            // Use widget.details
            return Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Center(
                  child: Text(
                          entry.key
                              .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'),
                                  (match) {
                                return '${match.group(1)} ${match.group(2)}';
                              })
                              .toUpperCase()
                              .replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center)),
                      Center(
                        child: Text(
                        entry.value.toString(),
                        textAlign: TextAlign.center,
                      )), // Properly display value
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ))]),
      ),
    );
  }
}

// class _DetailsState extends State<DetailsWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Invoice Details'),
//       ),
//       body: ListView.builder(
//         itemCount: widget.details.length,
//         itemBuilder: (context, index) {
//           final entry = widget.details.entries.elementAt(index);
//           final productDetails = entry.value;

//           return ListTile(
//             leading: Icon(Icons.shopping_cart), // Replace with your desired icon
//             title: Text(productDetails),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Purchase Date: MM-DD-YYYY'),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }