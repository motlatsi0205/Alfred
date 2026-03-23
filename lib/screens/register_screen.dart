// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Common controllers
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();

  // Store-specific controllers
  final _storeName = TextEditingController();
  final _location = TextEditingController();

  // Driver-specific controllers
  final _vehiclePlate = TextEditingController();

  String _selectedRole = 'customer';
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      switch (_selectedRole) {
        case 'customer':
          await AuthService.registerCustomer(
            _name.text.trim(),
            _email.text.trim(),
            _pass.text.trim(),
          );
          break;
        case 'store':
          await AuthService.createStoreAccount(
            storeName: _storeName.text.trim(),
            email: _email.text.trim(),
            password: _pass.text.trim(),
            location: _location.text.trim(),
            phone: _phone.text.trim(),
          );
          break;
        case 'driver':
          await AuthService.createDriverAccount(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _pass.text.trim(),
            phone: _phone.text.trim(),
            vehiclePlate: _vehiclePlate.text.trim(),
          );
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully')),
      );
      Navigator.pop(context); // go back to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Role selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['customer', 'store', 'driver'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 12),

            // Common fields
            if (_selectedRole == 'customer' || _selectedRole == 'driver')
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
            if (_selectedRole == 'store')
              TextField(
                controller: _storeName,
                decoration: const InputDecoration(labelText: 'Store Name'),
              ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),

            // Conditional fields
            if (_selectedRole == 'store' || _selectedRole == 'driver')
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),

            if (_selectedRole == 'store')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ),

            if (_selectedRole == 'driver')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _vehiclePlate,
                  decoration: const InputDecoration(labelText: 'Vehicle Plate'),
                ),
              ),

            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('Create Account'),
                  ),
          ],
        ),
      ),
    );
  }
}
