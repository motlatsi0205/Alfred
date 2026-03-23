// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController(); // Phone field controller
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      // We will update the auth service to accept the phone number
      final user = await AuthService.registerCustomer(
        _name.text.trim(),
        _email.text.trim(),
        _pass.text.trim(),
        _phone.text.trim(),
      );
      if (!mounted) return;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully')));
        Navigator.pop(context); // go back to login
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')), // Phone field
            const SizedBox(height: 8),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            _loading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
