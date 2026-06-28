import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _roleFilter = 'All'; // 'All', 'admin', 'user'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.getUsers();
      setState(() {
        _users = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load users: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesQuery = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phone.contains(_searchQuery);
        final matchesRole = _roleFilter == 'All' || user.role == _roleFilter;
        return matchesQuery && matchesRole;
      }).toList();
    });
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _toggleUserActiveStatus(UserModel user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    try {
      await DatabaseService.updateUserProfile(updated);
      _showSuccessSnackBar('User status updated successfully.');
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
  }

  Future<void> _editUser(UserModel user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    String selectedRole = user.role;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF150A2E),
          title: const Text('Edit User Profile', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: const Color(0xFF150A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final updated = user.copyWith(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole,
      );
      try {
        await DatabaseService.updateUserProfile(updated);
        _showSuccessSnackBar('User profile saved.');
        _loadUsers();
      } catch (e) {
        _showErrorSnackBar('Failed to save user: $e');
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to permanently delete user "${user.name}"? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.deleteUser(user.uid);
        _showSuccessSnackBar('User deleted successfully.');
        _loadUsers();
      } catch (e) {
        _showErrorSnackBar('Failed to delete user: $e');
      }
    }
  }

  void _showUserProfile(UserModel user) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF150A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileRow('UID', user.uid),
              _buildProfileRow('Email', user.email),
              _buildProfileRow('Phone', user.phone.isNotEmpty ? user.phone : 'Not Specified'),
              _buildProfileRow('Role', user.role.toUpperCase()),
              _buildProfileRow('Account Status', user.isActive ? 'Active' : 'Blocked'),
              _buildProfileRow('Registration Date', DateFormat('yMMMd').add_jm().format(user.createdDate)),
              _buildProfileRow('Last Login', DateFormat('yMMMd').add_jm().format(user.lastLogin)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Users Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text('View and edit profile metrics, activate/deactivate accounts, and adjust roles', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          const SizedBox(height: 28),
          
          // Search & Filter controls
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Email, or Phone...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8A00)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _roleFilter,
                  dropdownColor: const Color(0xFF150A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role Filter',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Roles')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _roleFilter = val;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No users matching the filters found.', style: TextStyle(color: Colors.white38)))
                    : GlassCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                cardColor: Colors.transparent,
                                dividerColor: Colors.white10,
                              ),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredUsers.map((user) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(user.name)),
                                      DataCell(Text(user.email)),
                                      DataCell(Text(user.phone.isNotEmpty ? user.phone : '—')),
                                      DataCell(Text(user.role.toUpperCase())),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: user.isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.isActive ? 'Active' : 'Blocked',
                                            style: TextStyle(
                                              color: user.isActive ? Colors.greenAccent : Colors.redAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_rounded, color: Colors.blueAccent, size: 18),
                                              onPressed: () => _showUserProfile(user),
                                              tooltip: 'View Profile',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Colors.orangeAccent, size: 18),
                                              onPressed: () => _editUser(user),
                                              tooltip: 'Edit Profile',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                user.isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded,
                                                color: user.isActive ? Colors.redAccent : Colors.greenAccent,
                                                size: 18,
                                              ),
                                              onPressed: () => _toggleUserActiveStatus(user),
                                              tooltip: user.isActive ? 'Block User' : 'Activate User',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                                              onPressed: () => _deleteUser(user),
                                              tooltip: 'Delete User',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
