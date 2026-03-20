import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CabDriversScreen extends StatefulWidget {
  const CabDriversScreen({super.key});

  @override
  State<CabDriversScreen> createState() => _CabDriversScreenState();
}

class _CabDriversScreenState extends State<CabDriversScreen> {
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
                        _showEditDriverDialog(doc);
                      } else if (value == 'delete') {
                        _deleteDriver(doc);
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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Driver'),
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

  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return confirmed;
  }

  // 🗑 Delete Driver
  Future<void> _deleteDriver(DocumentSnapshot driverDoc) async {
    final confirm = await _confirmDialog(
      title: 'Delete Driver',
      message: 'Are you sure you want to permanently delete this driver and their associated user data?',
    );

    if (!mounted) return;

    if (confirm) {
      try {
        final WriteBatch batch = FirebaseFirestore.instance.batch();
        final driverData = driverDoc.data() as Map<String, dynamic>;
        final String? ownerId = driverData['ownerUserId'];

        // 1. Delete driver document
        batch.delete(driverDoc.reference);

        // 2. If there is an owner, delete their user document
        if (ownerId != null && ownerId.isNotEmpty) {
          batch.delete(FirebaseFirestore.instance.collection('users').doc(ownerId));
        }

        await batch.commit();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver deleted successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting driver: $e')),
        );
      }
    }
  }

  // ✏️ Edit driver details
  void _showEditDriverDialog(DocumentSnapshot doc) {
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
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
