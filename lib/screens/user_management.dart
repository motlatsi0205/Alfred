import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // 🔹 Tabs for Customers, Stores, Drivers
  final List<String> _roles = ['customer', 'store', 'driver'];

  // 🔍 Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ➕ Add user controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'store';

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _roles.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: Colors.orange,
          bottom: TabBar(
            tabs: _roles
                .map(
                  (role) => Tab(
                    text:
                        '${role[0].toUpperCase()}${role.substring(1)}s',
                  ),
                )
                .toList(),
          ),
        ),
        body: Column(
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _roles.map(_buildUserList).toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _selectedRole = 'store';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name/Store Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['store', 'driver']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                              '${role[0].toUpperCase()}${role.substring(1)}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
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
            onPressed: _createUser,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // Add user details to Firestore
        final userId = user.uid;
        final userData = {
          'uid': userId,
          'name': name,
          'email': email,
          'phone': phone,
          'role': _selectedRole,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          if (_selectedRole == 'store') 'storeId': _uuid.v4(),
          if (_selectedRole == 'driver') 'driverId': _uuid.v4(),
        };

        await _firestore.collection('users').doc(userId).set(userData);

        if (mounted) {
          Navigator.pop(context); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unknown error occurred: $e')),
        );
      }
    }
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'admin') return false;

          if (_searchQuery.isEmpty) return true;

          final name =
              (data['name'] ?? data['storeName'] ?? '')
                  .toString()
                  .toLowerCase();
          final email =
              (data['email'] ?? '').toString().toLowerCase();

          return name.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();

        // Active users first
        users.sort((a, b) {
          final aStatus =
              (a.data() as Map<String, dynamic>)['status'] ?? 'active';
          final bStatus =
              (b.data() as Map<String, dynamic>)['status'] ?? 'active';
          if (aStatus == bStatus) return 0;
          return aStatus == 'active' ? -1 : 1;
        });

        if (users.isEmpty) {
          return const Center(child: Text('No matching users.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;

            

                        final name = data['name'] ?? data['storeName'] ?? 'No Name';

                        final email = data['email'] ?? 'No Email';

                        final role = data['role'] ?? 'Unknown';

                        final status = data['status'] ?? 'active';

                        final isBlocked = status == 'blocked';

            

                        // New details

                        final phone = data['phone'] ?? 'No Phone';

                        final storeId = data['storeId'] ?? '';

                        final driverId = data['driverId'] ?? '';

            

                        return Card(

                          elevation: 3,

                          margin: const EdgeInsets.symmetric(vertical: 8),

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: ListTile(

                            leading: CircleAvatar(

                              backgroundColor:

                                  isBlocked ? Colors.redAccent : Colors.green,

                              child: Icon(

                                isBlocked ? Icons.block : Icons.person,

                                color: Colors.white,

                              ),

                            ),

                            title: Text(name),

                            subtitle: RichText(

                              text: TextSpan(

                                style: const TextStyle(

                                  color: Colors.grey,

                                  fontSize: 14,

                                ),

                                children: [

                                  TextSpan(text: '$email\n'),

                                  TextSpan(

                                    text: 'Role: $role, Status: $status\n',

                                    style: const TextStyle(

                                      fontWeight: FontWeight.bold,

                                    ),

                                  ),

                                  TextSpan(text: 'Phone: $phone\n'),

                                  if (role == 'store' && storeId.isNotEmpty)

                                    TextSpan(text: 'Store ID: $storeId\n'),

                                  if (role == 'driver' && driverId.isNotEmpty)

                                    TextSpan(text: 'Driver ID: $driverId\n'),

                                ],

                              ),

                            ),

                            isThreeLine: true,

                            trailing: PopupMenuButton<String>(

                              onSelected: (value) {

                                if (value == 'view') {

                                  _showUserDetails(doc);

                                } else if (value == 'block') {

                                  _toggleBlock(doc.id, isBlocked);

                                } else if (value == 'change_role') {

                                  _showRoleChangeDialog(doc.id, role);

                                } else if (value == 'delete') {

                                  _deleteUser(doc);

                                }

                              },

                              itemBuilder: (context) => [

                                const PopupMenuItem(

                                  value: 'view',

                                  child: Text('View Details'),

                                ),

                                PopupMenuItem(

                                  value: 'block',

                                  child: Text(

                                    isBlocked ? 'Unblock User' : 'Block User',

                                  ),

                                ),

                                const PopupMenuItem(

                                  value: 'change_role',

                                  child: Text('Change Role'),

                                ),

                                const PopupMenuItem(

                                  value: 'delete',

                                  child: Text('Delete User'),

                                ),

                              ],

                            ),

                          ),

                        );

                      },

                    );

                  },

                );

              }

            

              // 🔍 View Details

              void _showUserDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Name',
                  data['name'] ?? data['storeName'] ?? '—'),
              _detailRow('Email', data['email'] ?? '—'),
              _detailRow('Role', data['role'] ?? '—'),
              _detailRow('Status', data['status'] ?? 'active'),
              _detailRow('Phone', data['phone'] ?? '—'),
              if (role == 'store')
                _detailRow('Store ID', data['storeId'] ?? '—'),
              if (role == 'driver')
                _detailRow('Driver ID', data['driverId'] ?? '—'),
              _detailRow(
                'Created At',
                data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp)
                        .toDate()
                        .toString()
                    : '—',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

            

              Widget _detailRow(String label, String value) {

                return Padding(

                  padding: const EdgeInsets.only(bottom: 8),

                  child: RichText(

                    text: TextSpan(

                      style: const TextStyle(color: Colors.black),

                      children: [

                        TextSpan(

                          text: '$label: ',

                          style:

                              const TextStyle(fontWeight: FontWeight.bold),

                        ),

                        TextSpan(text: value),

                      ],

                    ),

                  ),

                );

              }

            

              // 🔒 Block / Unblock

              Future<void> _toggleBlock(String userId, bool blocked) async {

                final confirm = await _confirmDialog(

                  title: blocked ? 'Unblock User' : 'Block User',

                  message: blocked

                      ? 'Allow this user to log in again?'

                      : 'Prevent this user from logging in?',

                );

            

                if (confirm) {

                  await _firestore.collection('users').doc(userId).update({

                    'status': blocked ? 'active' : 'blocked',

                  });

                }

              }

            

              // 🗑 Delete

              Future<void> _deleteUser(DocumentSnapshot userDoc) async {

                final confirm = await _confirmDialog(

                  title: 'Delete User',

                  message: 'Are you sure you want to permanently delete this user and all their associated data from the database?',

                );

            

                if (!mounted) return;

            

                if (confirm) {

                  final String userId = userDoc.id;

                  final data = userDoc.data() as Map<String, dynamic>;

                  final String role = data['role'] ?? 'customer';

            

                  // NOTE: This will NOT delete the user from Firebase Authentication.

                  // That would require a backend function with admin privileges.

                  // The user will still be able to log in, but their data will be gone from the database.

            

                  try {

                    final WriteBatch batch = _firestore.batch();

            

                    // 1. Delete the main user document

                    batch.delete(_firestore.collection('users').doc(userId));

            

                    // 2. If the user is a 'store' or 'driver', delete their associated data

                    if (role == 'store') {

                      // Find store document by ownerUserId and delete it

                      final storeQuery = await _firestore.collection('stores').where('ownerUserId', isEqualTo: userId).limit(1).get();

                      if (storeQuery.docs.isNotEmpty) {

                        batch.delete(storeQuery.docs.first.reference);

                      }

                    } else if (role == 'driver') {

                      // Find driver document by ownerUserId and delete it

                      final driverQuery = await _firestore.collection('drivers').where('ownerUserId', isEqualTo: userId).limit(1).get();

                      if (driverQuery.docs.isNotEmpty) {

                        batch.delete(driverQuery.docs.first.reference);

                      }

                    }

            

                    // Commit the batch operation

                    await batch.commit();

            

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(

                      const SnackBar(content: Text('User data deleted successfully.')),

                    );

                  } catch (e) {

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(

                      SnackBar(content: Text('Error deleting user: $e')),

                    );

                  }

                }

              }

            

              // 🔁 Change Role

              Future<void> _showRoleChangeDialog(

                  String userId, String currentRole) async {

                String? newRole = currentRole;

            

                await showDialog(

                  context: context,

                  builder: (_) => AlertDialog(

                    title: const Text('Change User Role'),

                    content: StatefulBuilder(

                      builder: (_, setState) => DropdownButton<String>(

                        value: newRole,

                        isExpanded: true,

                        items: _roles

                            .map(

                              (r) =>

                                  DropdownMenuItem(value: r, child: Text(r)),

                            )

                            .toList(),

                        onChanged: (value) => setState(() {

                          newRole = value;

                        }),

                      ),

                    ),

                    actions: [

                      TextButton(

                        onPressed: () => Navigator.pop(context),

                        child: const Text('Cancel'),

                      ),

                      ElevatedButton(

                        onPressed: () async {

                          if (newRole != null && newRole != currentRole) {

                            await _firestore

                                .collection('users')

                                .doc(userId)

                                .update({'role': newRole});

                          }

                          if (!mounted) return;

                          Navigator.pop(context);

                        },

                        style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.orange),

                        child: const Text('Update'),

                      ),

                    ],

                  ),

                );

              }

              

              // ❓ Confirm dialog

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

            }

            
