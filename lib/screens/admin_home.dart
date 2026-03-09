import 'package:flutter/material.dart';
import 'user_management.dart';
import 'partner_stores_screen.dart';
import 'cab_drivers_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // TODO: Add logout logic (FirebaseAuth.instance.signOut())
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
           _buildAdminCard(
  context,
  icon: Icons.people,
  label: 'User Management',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
    );
  },
),
            _buildAdminCard(
              context,
              icon: Icons.store_mall_directory,
              label: 'Partner Stores',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerStoresScreen()),
                );
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.local_shipping,
              label: 'Cab Drivers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CabDriversScreen()),
                );
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.attach_money,
              label: 'Transactions & Orders',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transactions & Orders coming soon...')),
                );
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.inventory,
              label: 'Inventory & Pricing',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventory & Pricing coming soon...')),
                );
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.settings,
              label: 'System Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System Settings coming soon...')),
                );
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.notifications_active,
              label: 'Notifications & Feedback',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔸 Helper widget for uniform admin cards
  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}