import 'package:flutter/material.dart';
import '../models/trolley_item.dart';
import 'trolley_screen.dart';
import '../data/price_data.dart';

class PriceComparisonScreen extends StatelessWidget {
  final String? itemName;
  final List<String>? itemList;

  const PriceComparisonScreen({super.key, this.itemName, this.itemList})
      : assert(itemName != null || itemList != null,
            'Either itemName or itemList must be provided');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(itemName != null ? "Prices for $itemName" : "Compare Full List"),
        backgroundColor: Colors.orange,
      ),
      body: itemName != null ? _buildSingleItem(context) : _buildFullList(context),
    );
  }

  /// 🛒 Compare one item
  Widget _buildSingleItem(BuildContext context) {
    final storePrices = mockPrices[itemName] ?? {};

    if (storePrices.isEmpty) {
      return const Center(child: Text("No price data available for this item"));
    }

    // Find cheapest store
    final cheapestEntry = storePrices.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: storePrices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = storePrices.entries.elementAt(index);
        final isCheapest = entry.key == cheapestEntry.key;
        final item = TrolleyItem(
          itemName: itemName!,
          storeName: entry.key,
          price: entry.value,
        );

        return Card(
          child: ListTile(
            leading: const Icon(Icons.store, color: Colors.orange),
            title: Row(
              children: [
                Text(entry.key),
                if (isCheapest)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Cheapest",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            subtitle: Text("M ${entry.value.toStringAsFixed(2)}"),
            trailing: ElevatedButton(
              onPressed: () {
                TrolleyScreen.addToTrolley(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${item.itemName} added to trolley from ${item.storeName}'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ),
        );
      },
    );
  }

  /// 🛍️ Compare the full list
  Widget _buildFullList(BuildContext context) {
    final totals = <String, double>{};

    // Collect all items per store
    final storeItems = <String, List<TrolleyItem>>{};

    for (final item in itemList!) {
      final storePrices = mockPrices[item];
      if (storePrices != null) {
        storePrices.forEach((store, price) {
          totals[store] = (totals[store] ?? 0) + price;

          storeItems.putIfAbsent(store, () => []);
          storeItems[store]!.add(
            TrolleyItem(itemName: item, storeName: store, price: price),
          );
        });
      }
    }

    if (totals.isEmpty) {
      return const Center(child: Text("No price data available for your list"));
    }

    // Sort stores by total price
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final cheapestEntry = sortedEntries.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Comparing ${itemList!.length} items:",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sortedEntries.map((entry) {
          final isCheapest = entry.key == cheapestEntry.key;
          return Card(
            child: ListTile(
              leading:
                  const Icon(Icons.store_mall_directory, color: Colors.orange),
              title: Row(
                children: [
                  Text(entry.key),
                  if (isCheapest)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Cheapest",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                "M ${entry.value.toStringAsFixed(2)}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  for (final item in storeItems[entry.key]!) {
                    TrolleyScreen.addToTrolley(item);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "All ${itemList!.length} items added to trolley from ${entry.key}"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add All"),
              ),
            ),
          );
        }),
      ],
    );
  }
}