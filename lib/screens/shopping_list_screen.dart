import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'price_comparison_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items = prefs.getStringList('shopping_list') ?? [];
    });
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shopping_list', _items);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter item name'),
            autofocus: true,
            onSubmitted: (_) => _submitAdd(controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitAdd(controller),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _submitAdd(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      setState(() => _items.add(text));
      _saveItems();
      Navigator.pop(context);
    }
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _saveItems();
  }

  void _openPriceComparison(String itemName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PriceComparisonScreen(itemName: itemName),
      ),
    );
  }

  void _openFullListComparison() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your shopping list is empty")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PriceComparisonScreen(itemList: _items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.orange,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: "Compare Full List",
              onPressed: _openFullListComparison,
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Your shopping list is empty. Tap + to add items.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_basket),
                    title: Text(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                      tooltip: 'Delete',
                    ),
                    onTap: () => _openPriceComparison(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
