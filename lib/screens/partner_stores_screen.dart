import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerStoresScreen extends StatelessWidget {
  const PartnerStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Stores'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No partner stores found.'));
          }

          final stores = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final doc = stores[index];
              final data = doc.data() as Map<String, dynamic>;

              final isActive = data['isActive'] ?? true;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isActive ? Colors.green : Colors.grey,
                    child: const Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Store'),
                  subtitle: Text(
                    '${data['location'] ?? 'No location'}\n'
                    'Status: ${isActive ? 'Active' : 'Inactive'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggle') {
                        _toggleStoreStatus(doc.id, isActive);
                      } else if (value == 'edit') {
                        _showEditStoreDialog(context, doc);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          isActive ? 'Deactivate Store' : 'Activate Store',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Store'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔁 Activate / Deactivate store (business-level)
  Future<void> _toggleStoreStatus(String storeId, bool isActive) async {
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .update({'isActive': !isActive});
  }

  // ✏️ Edit store details
  void _showEditStoreDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final name = TextEditingController(text: data['name']);
    final phone = TextEditingController(text: data['phone']);
    final location = TextEditingController(text: data['location']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Store'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Store Name'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('stores')
                  .doc(doc.id)
                  .update({
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'location': location.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
