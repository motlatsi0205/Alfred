import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trolley_item.dart';

class TrolleyScreen extends StatefulWidget {
  const TrolleyScreen({super.key});

  // static method to add items to trolley
  static Future<void> addToTrolley(TrolleyItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('trolley') ?? [];
    data.add(jsonEncode(item.toJson()));
    await prefs.setStringList('trolley', data);
  }

  @override
  State<TrolleyScreen> createState() => _TrolleyScreenState();
}

class _TrolleyScreenState extends State<TrolleyScreen> {
  List<TrolleyItem> _trolley = [];

  @override
  void initState() {
    super.initState();
    _loadTrolley();
  }

  Future<void> _loadTrolley() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('trolley') ?? [];
    setState(() {
      _trolley = data.map((e) => TrolleyItem.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveTrolley() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _trolley.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('trolley', data);
  }

  Future<void> _clearTrolley() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trolley');
    setState(() => _trolley.clear());
  }

  Future<void> _removeItem(TrolleyItem item) async {
    setState(() {
      _trolley.remove(item);
    });
    await _saveTrolley();
  }

  Future<void> _checkoutStore(String storeName, List<TrolleyItem> items) async {
    setState(() {
      _trolley.removeWhere((item) => item.storeName == storeName);
    });
    await _saveTrolley();

    final storeTotal = items.fold(0.0, (sum, item) => sum + item.price);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Checked out ${items.length} items from $storeName (M ${storeTotal.toStringAsFixed(2)})",
        ),
      ),
    );
  }

  Future<void> _checkoutAll() async {
    final grandTotal = _trolley.fold(0.0, (sum, item) => sum + item.price);
    final itemCount = _trolley.length;

    await _clearTrolley();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Checked out all $itemCount items (M ${grandTotal.toStringAsFixed(2)})",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_trolley.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trolley'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: Text('Your trolley is empty.')),
      );
    }

    // Group items by store
    final Map<String, List<TrolleyItem>> grouped = {};
    for (final item in _trolley) {
      grouped.putIfAbsent(item.storeName, () => []);
      grouped[item.storeName]!.add(item);
    }

    // Build children list
    final List<Widget> children = [];
    double grandTotal = 0.0;

    for (final entry in grouped.entries) {
      final storeName = entry.key;
      final items = entry.value;

      final storeTotal = items.fold(0.0, (sum, item) => sum + item.price);
      grandTotal += storeTotal;

      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                ...items.map((item) => ListTile(
                      leading:
                          const Icon(Icons.shopping_cart, color: Colors.orange),
                      title: Text(item.itemName),
                      subtitle: Text("M ${item.price.toStringAsFixed(2)}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeItem(item),
                      ),
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Subtotal: M ${storeTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _checkoutStore(storeName, items),
                        icon: const Icon(Icons.payment),
                        label: const Text("Checkout Store"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Add grand total widget and checkout all button
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Grand Total: M ${grandTotal.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _checkoutAll,
              icon: const Icon(Icons.shopping_bag),
              label: const Text("Checkout All"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trolley'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear Trolley',
            onPressed: () {
              _clearTrolley();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trolley cleared')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}