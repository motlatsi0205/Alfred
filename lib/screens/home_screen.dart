import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alfred_app/screens/admin_home.dart';
import 'package:alfred_app/screens/driver_dashboard.dart';
import 'package:alfred_app/screens/login_screen.dart';
import 'package:alfred_app/screens/store_dashboard.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      setState(() {
        _user = user;
      });
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
          });
        }
      } else {
        setState(() {
          _userData = null;
        });
      }
    });
  }

  void _navigateToPanel() {
    final role = _userData?['role'];
    if (role == null) return;

    Widget page;
    switch (role) {
      case 'admin':
        page = const AdminHome();
        break;
      case 'driver':
        page = const DriverDashboard();
        break;
      case 'store':
        page = const StoreDashboard();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final userRole = _userData?['role'];
    final canSeePanelButton = userRole == 'admin' || userRole == 'driver' || userRole == 'store';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alfred'),
        backgroundColor: Colors.orange,
        actions: [
          if (_user == null)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                "Login",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          else ...[
            if (canSeePanelButton)
              IconButton(
                icon: const Icon(Icons.dashboard),
                tooltip: 'Dashboard',
                onPressed: _navigateToPanel,
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _user != null ? 'Welcome, ${_userData?['name'] ?? ''}!' : 'Welcome to Alfred!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  CategoryCard(title: 'Groceries', icon: Icons.local_grocery_store),
                  CategoryCard(title: 'Electronics', icon: Icons.devices),
                  CategoryCard(title: 'Household', icon: Icons.home),
                  CategoryCard(title: 'Clothing', icon: Icons.checkroom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
