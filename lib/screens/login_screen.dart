// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../main.dart'; // customer app home
import 'store_dashboard.dart';
import 'driver_dashboard.dart';
import 'register_screen.dart';
import 'admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.login(
        _email.text.trim(),
        _pass.text.trim(),
      );

      if (user == null) throw Exception('No user found');

      // 🧠 Fetch Firestore user document
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record not found.')),
        );
        return;
      }

      final data = doc.data()!;
      final role = data['role'] as String?;
      final status = data['status'] ?? 'active';

      // 🛑 Prevent blocked users from logging in
      if (status == 'blocked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been blocked by admin.')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (role == null) {
        throw Exception('User role not set.');
      }

      // 🧭 Route based on role
      switch (role) {
        case 'customer':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
          break;

        case 'store':
          final storeId = data['storeId'] as String?;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDashboard(storeId: storeId ?? ''),
            ),
          );
          break;

        case 'driver':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverDashboard()),
          );
          break;

        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHome()),
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown user role')),
          );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Login'),
                  ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Register as Customer'),
            ),
          ],
        ),
      ),
    );
  }
}