import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _majorKey = 'profile_major';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(authControllerProvider).user;
    final prefs = await SharedPreferences.getInstance();

    _nameController.text = user?.name ?? '';
    _majorController.text = prefs.getString(_majorKey) ?? '';
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_majorKey, _majorController.text.trim());
      await ref.read(authControllerProvider.notifier).completeProfileSetup(
            name: _nameController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));

      context.go('/home');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lengkapi profil kamu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _majorController,
                  decoration: const InputDecoration(labelText: 'Jurusan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jurusan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (isLoading || _isSaving) ? null : _saveProfile,
                  child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
