import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersManagementScreen extends StatefulWidget {
  final String initialRoleFilter;

  const UsersManagementScreen({super.key, this.initialRoleFilter = 'all'});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> users = [];
  String searchQuery = '';
  String roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    roleFilter = widget.initialRoleFilter;
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        users = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _inviteAdmin() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Administrator'),
        content: TextField(
          controller: emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'admin@example.com',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
    emailController.dispose();

    if (email == null || email.isEmpty || !mounted) return;

    try {
      await supabase.functions.invoke('invite-admin', body: {'email': email});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Administrator invitation sent to $email.')),
      );
      await loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to invite administrator: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((u) {
      final role = (u['role']?.toString() ?? 'student').toLowerCase();
      final name = (u['full_name']?.toString() ?? '').toLowerCase();
      final email = (u['email']?.toString() ?? '').toLowerCase();

      final matchesRole = roleFilter == 'all' || role == roleFilter;
      final matchesSearch =
          searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          email.contains(searchQuery.toLowerCase());

      return matchesRole && matchesSearch;
    }).toList();
  }

  Future<void> _editRole(Map<String, dynamic> user) async {
    String currentRole = user['role']?.toString() ?? 'student';
    String newRole = currentRole;
    final userId = user['id'].toString();
    final userName = user['full_name']?.toString() ?? 'User';

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role - $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Student'),
                subtitle: const Text('Access to student portal and courses'),
                value: 'student',
                groupValue: newRole,
                onChanged: (v) => setDialogState(() => newRole = v!),
              ),
              RadioListTile<String>(
                title: const Text('Teacher'),
                subtitle: const Text(
                  'Access to staff portal, course creation & grading',
                ),
                value: 'teacher',
                groupValue: newRole,
                onChanged: (v) => setDialogState(() => newRole = v!),
              ),
              RadioListTile<String>(
                title: const Text('Admin'),
                subtitle: const Text(
                  'Full administrative access across platform',
                ),
                value: 'admin',
                groupValue: newRole,
                onChanged: (v) => setDialogState(() => newRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                try {
                  await supabase.functions.invoke(
                    'admin-update-user-role',
                    body: {'user_id': userId, 'role': newRole},
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $userName role to $newRole')),
      );
      await loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Users & Role Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _inviteAdmin,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Invite Admin'),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load users: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loading ? null : loadUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Filter and search
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search users by name or email...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) => setState(() => searchQuery = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: roleFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Roles'),
                              ),
                              DropdownMenuItem(
                                value: 'teacher',
                                child: Text('Teachers'),
                              ),
                              DropdownMenuItem(
                                value: 'student',
                                child: Text('Students'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admins'),
                              ),
                            ],
                            onChanged: (v) => setState(() => roleFilter = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Users List
                  Expanded(
                    child: displayed.isEmpty
                        ? Center(
                            child: Text(
                              'No users matching the filters.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            itemCount: displayed.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final u = displayed[index];
                              final name = u['full_name']?.toString() ?? 'User';
                              final email = u['email']?.toString() ?? '';
                              final role = (u['role']?.toString() ?? 'student')
                                  .toLowerCase();

                              Color badgeColor = const Color(0xFFEFFFD8);
                              Color textColor = const Color(0xFF65A30D);
                              if (role == 'admin') {
                                badgeColor = Colors.purple.shade50;
                                textColor = Colors.purple.shade700;
                              } else if (role == 'student') {
                                badgeColor = Colors.blue.shade50;
                                textColor = Colors.blue.shade700;
                              }

                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: textColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: textColor,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    email.isNotEmpty
                                        ? email
                                        : 'No email provided',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Change Role',
                                        icon: const Icon(
                                          Icons.manage_accounts_outlined,
                                          size: 22,
                                        ),
                                        onPressed: () => _editRole(u),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
