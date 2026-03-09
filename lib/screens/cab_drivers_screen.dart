import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CabDriversScreen extends StatelessWidget {
  const CabDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cab Drivers'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No drivers found.'));
          }

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final doc = drivers[index];
              final data = doc.data() as Map<String, dynamic>;

              final isActive = data['isActive'] ?? true;
              final isAvailable = data['isAvailable'] ?? false;

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
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Driver'),
                  subtitle: Text(
                    'Vehicle: ${data['vehiclePlate'] ?? '—'}\n'
                    'Available: ${isAvailable ? 'Yes' : 'No'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggle_active') {
                        _toggleActive(doc.id, isActive);
                      } else if (value == 'toggle_available') {
                        _toggleAvailability(doc.id, isAvailable);
                      } else if (value == 'edit') {
                        _showEditDriverDialog(context, doc);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: Text(
                          isActive
                              ? 'Deactivate Driver'
                              : 'Activate Driver',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_available',
                        child: Text(
                          isAvailable
                              ? 'Set Offline'
                              : 'Set Available',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Driver'),
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

  // 🔁 Activate / Deactivate driver (business-level)
  Future<void> _toggleActive(String driverId, bool isActive) async {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({'isActive': !isActive});
  }

  // 🚦 Availability toggle
  Future<void> _toggleAvailability(
    String driverId,
    bool isAvailable,
  ) async {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({'isAvailable': !isAvailable});
  }

  // ✏️ Edit driver details
  void _showEditDriverDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final name = TextEditingController(text: data['name']);
    final phone = TextEditingController(text: data['phone']);
    final vehicle =
        TextEditingController(text: data['vehiclePlate']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Driver'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: vehicle,
                decoration:
                    const InputDecoration(labelText: 'Vehicle Plate'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(doc.id)
                  .update({
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'vehiclePlate': vehicle.text.trim(),
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
