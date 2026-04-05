import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final healthState = ref.watch(healthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _ProfileHeader(user: user, colorScheme: colorScheme),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Account'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.person,
                    title: 'Personal details',
                    subtitle: 'Edit your name',
                    onTap: () => _editName(context, ref, user.name),
                  ),
                  const Divider(height: 0),
                  _SettingTile(
                    icon: Icons.accessibility,
                    title: 'Body profile',
                    subtitle: 'Age: ${user.age ?? '-'}, H: ${user.height ?? '-'} cm, W: ${user.weight ?? '-'} kg',
                    onTap: () => _editBodyProfile(context, ref, user),
                  ),
                  const Divider(height: 0),
                  _SettingTile(
                    icon: Icons.flag,
                    title: 'Goals',
                    subtitle: 'Change daily calorie target: ${user.dailyCalorieGoal.toInt()} kcal',
                    onTap: () => _editGoal(context, ref, user.dailyCalorieGoal),
                  ),
                  const Divider(height: 0),
                  Consumer(
                    builder: (context, ref, child) {
                      final themeMode = ref.watch(themeProvider);
                      final isDark = themeMode == ThemeMode.dark;
                      return SwitchListTile(
                        value: isDark,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Integrations'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.favorite,
                    title: 'Health apps',
                    subtitle: healthState.isSynced 
                        ? 'Apple Health / Google Fit (Synced)'
                        : 'Apple Health / Google Fit (Not Synced)',
                    onTap: () async {
                      if (healthState.isSynced) {
                        ref.read(healthProvider.notifier).disconnectSync();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Health sync disconnected.')),
                        );
                      } else {
                        final success = await ref.read(healthProvider.notifier).initiateSync();
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Health sync connected successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to connect or permissions denied.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const _LogoutTile(),
            ),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).updateName(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editGoal(BuildContext context, WidgetRef ref, double currentGoal) {
    final controller = TextEditingController(text: currentGoal.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'kcal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                ref.read(userProvider.notifier).updateGoal(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBodyProfile(BuildContext context, WidgetRef ref, UserModel user) {
    final ageController = TextEditingController(text: user.age?.toString() ?? '');
    final heightController = TextEditingController(text: user.height?.toString() ?? '');
    final weightController = TextEditingController(text: user.weight?.toString() ?? '');
    String selectedGender = user.gender ?? 'Male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Body Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
                const SizedBox(height: 8),
                TextField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)')),
                const SizedBox(height: 8),
                TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => selectedGender = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).updateBodyProfile(
                  age: int.tryParse(ageController.text),
                  height: double.tryParse(heightController.text),
                  weight: double.tryParse(weightController.text),
                  gender: selectedGender,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserModel user;
  final ColorScheme colorScheme;

  const _ProfileHeader({required this.user, required this.colorScheme});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ref.read(userProvider.notifier).updateProfileImage(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _pickImage(context, ref),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: user.profileImagePath != null
                    ? FileImage(File(user.profileImagePath!))
                    : null,
                child: user.profileImagePath == null
                    ? Icon(
                        Icons.person,
                        size: 36,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI Nutrition Profile Active',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Log out',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        ref.read(authProvider.notifier).logout();
      },
    );
  }
}