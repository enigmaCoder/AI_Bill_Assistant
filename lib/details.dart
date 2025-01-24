
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailsWidget extends StatefulWidget {
  const DetailsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _DetailsState();
}

class _DetailsState extends State<DetailsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber
      ),
      child: Column(
        children: [
          Text("Hello Shubham")
        ],
      ),
    );
  }
}