import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String itemName;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const ItemCard({
    Key? key,
    required this.itemName,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(itemName),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: onSubmit,
                  child: const Text('Submit'),
                ),
                ElevatedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class ItemCardList extends StatefulWidget {
  @override
  _ItemCardListState createState() => _ItemCardListState();
}

class _ItemCardListState extends State<ItemCardList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizontal Item Cards')),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SlideTransition(
            position: _animation,
            child: Row(
              children: List.generate(5, (index) {  // Replace with your actual item count
                return ItemCard(
                  itemName: 'Item ${index + 1}', // Replace with your dynamic item name
                  onSubmit: () {
                    // Handle submit action
                    print('Submitted item ${index + 1}');
                  },
                  onCancel: () {
                    // Handle cancel action
                    print('Cancelled item ${index + 1}');
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
