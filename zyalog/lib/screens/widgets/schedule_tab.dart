// lib/screens/widgets/schedule_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import 'add_schedule_sheet.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  void _showAddSheet(BuildContext context, {ScheduleModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddScheduleSheet(editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ScheduleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final byHari = prov.byHari;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: kHariKeys.length,
      itemBuilder: (_, i) {
        final hari = kHariKeys[i];
        final items = byHari[hari] ?? [];
        return _HariSection(
          hari: hari,
          label: kHariLabel[hari]!,
          items: items,
          isDark: isDark,
          onAdd: () => _showAddSheet(context),
          onEdit: (s) => _showAddSheet(context, editing: s),
          onDelete: (id) => prov.deleteSchedule(id),
        );
      },
    );
  }
}

class _HariSection extends StatelessWidget {
  final String hari;
  final String label;
  final List<ScheduleModel> items;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(ScheduleModel) onEdit;
  final void Function(String) onDelete;

  const _HariSection({
    required this.hari,
    required this.label,
    required this.items,
    required this.isDark,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: items.isNotEmpty
                      ? AppTheme.accent.withAlpha(31)
                      : (isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: items.isNotEmpty
                        ? AppTheme.accent
                        : (isDark
                            ? AppTheme.darkSubtext
                            : AppTheme.lightSubtext),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Text(
                  '${items.length} kelas',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Center(
                child: Text(
                  'Tidak ada kelas',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                  ),
                ),
              ),
            )
          else
            ...items.map((s) => _ScheduleCard(
                  schedule: s,
                  isDark: isDark,
                  onEdit: () => onEdit(s),
                  onDelete: () => onDelete(s.id),
                )),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          // Time indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  schedule.jamMulai,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
                Text(
                  schedule.jamSelesai,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.mataKuliah,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                if (schedule.ruang.isNotEmpty)
                  Text(
                    '📍 ${schedule.ruang}',
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 18,
                color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext),
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('Edit',
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text('Hapus', style: TextStyle(color: AppTheme.accent)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
