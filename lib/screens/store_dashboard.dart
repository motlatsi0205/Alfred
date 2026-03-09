import 'package:flutter/material.dart';

class StoreDashboard extends StatelessWidget {
  final String storeId;

  const StoreDashboard({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Store Dashboard"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Text(
          "Welcome Store Owner!\nStore ID: $storeId",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}