// lib/screens/widgets/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      child: Column(
        children: [
          // ── Avatar & Info ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      (user?.displayName.isNotEmpty == true)
                          ? user!.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? '-',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Summary Stats ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Tugas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoTile(
                      label: 'Total',
                      value: '${tasks.totalCount}',
                      icon: Icons.list_alt_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _InfoTile(
                      label: 'Selesai',
                      value: '${tasks.completedCount}',
                      icon: Icons.check_circle_outline,
                      isDark: isDark,
                      color: AppTheme.emerald,
                    ),
                    const SizedBox(width: 8),
                    _InfoTile(
                      label: 'Belum',
                      value: '${tasks.pendingCount}',
                      icon: Icons.pending_outlined,
                      isDark: isDark,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tasks.progress,
                    backgroundColor:
                        isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    color: AppTheme.emerald,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Progres: ${(tasks.progress * 100).round()}% selesai',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkSubtext
                        : AppTheme.lightSubtext,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Theme toggle ─────────────────────────────────────────────────
          _SettingTile(
            icon: isDark ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
            title: isDark ? 'Mode Terang' : 'Mode Gelap',
            subtitle: 'Ubah tampilan aplikasi',
            isDark: isDark,
            trailing: Switch(
              value: isDark,
              activeThumbColor: AppTheme.accent,
              onChanged: (_) => auth.toggleTheme(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Logout ────────────────────────────────────────────────────────
          _SettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Keluar dari akun',
            isDark: isDark,
            iconColor: AppTheme.accent,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Konfirmasi Logout',
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                          fontWeight: FontWeight.w600)),
                  content: Text('Yakin ingin keluar dari akun?',
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.darkSubtext
                              : AppTheme.lightSubtext)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<TaskProvider>().clear();
                context.read<ScheduleProvider>().clear();
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              }
            },
          ),

          const SizedBox(height: 24),
          Text(
            'ZyaLog v1.0.0 • Kelola Jadwal & Tugas Kuliah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color? color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText)),
            Text(label,
                style: TextStyle(fontSize: 10, color: c)),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.darkSubtext).withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: iconColor ??
                      (isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkSubtext
                              : AppTheme.lightSubtext)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right,
                  size: 18,
                  color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext),
          ],
        ),
      ),
    );
  }
}
