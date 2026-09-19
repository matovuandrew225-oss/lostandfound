import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Campus member';
    final email = user?.email ?? 'No email available';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        )),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFEAF0F7),
                          child: Text(
                            name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 5),
                            Text(email, style: const TextStyle(color: AppTheme.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: const Text('My reports'),
                        subtitle: const Text('Track your lost and found items'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bookmark_border),
                        title: const Text('Saved items'),
                        subtitle: const Text('Listings you want to revisit'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_outlined),
                        title: const Text('Reset password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Supabase.instance.client.auth.resetPasswordForEmail(email);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset email sent.')),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.burgundy),
                        title: const Text('Sign out', style: TextStyle(color: AppTheme.burgundy)),
                        onTap: () => Supabase.instance.client.auth.signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
