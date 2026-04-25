// lib/screens/widgets/task_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import 'add_task_sheet.dart';

class TaskTab extends StatelessWidget {
  const TaskTab({super.key});

  void _showAddSheet(BuildContext context, {TaskModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Column(
      children: [
        // ── Stats + Progress bar ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StatBadge(
                      label: 'Semua',
                      value: prov.totalCount,
                      isDark: isDark),
                  const SizedBox(width: 8),
                  _StatBadge(
                      label: 'Belum',
                      value: prov.pendingCount,
                      isDark: isDark),
                  const SizedBox(width: 8),
                  _StatBadge(
                      label: 'Selesai',
                      value: prov.completedCount,
                      isDark: isDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prov.progress,
                        backgroundColor:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        color: AppTheme.emerald,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(prov.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.emerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Filter chips ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _FilterChip(
                  label: 'Semua',
                  isSelected: prov.filter == TaskFilter.all,
                  onTap: () => prov.setFilter(TaskFilter.all)),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Belum Selesai',
                  isSelected: prov.filter == TaskFilter.pending,
                  onTap: () => prov.setFilter(TaskFilter.pending)),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Selesai',
                  isSelected: prov.filter == TaskFilter.done,
                  onTap: () => prov.setFilter(TaskFilter.done)),
            ],
          ),
        ),

        // ── Task list ─────────────────────────────────────────────────────
        Expanded(
          child: prov.filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48,
                          color: isDark
                              ? AppTheme.darkSubtext
                              : AppTheme.lightSubtext),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada tugas',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkSubtext
                              : AppTheme.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: prov.filteredTasks.length,
                  itemBuilder: (_, i) {
                    final task = prov.filteredTasks[i];
                    return _TaskCard(
                      task: task,
                      isDark: isDark,
                      onToggle: () => prov.toggleCompleted(task.id),
                      onEdit: () => _showAddSheet(context, editing: task),
                      onDelete: () => prov.deleteTask(task.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final bool isDark;

  const _StatBadge(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withAlpha(31)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.accent : AppTheme.darkSubtext,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final isUrgent = task.isWithinNextHours(24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent && !task.completed
              ? AppTheme.accent.withAlpha(128)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  task.completed ? AppTheme.emerald : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: task.completed
                    ? AppTheme.emerald
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                width: 1.5,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: task.completed
                ? (isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext)
                : (isDark ? AppTheme.darkText : AppTheme.lightText),
            decoration:
                task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 12,
                  color: isUrgent && !task.completed
                      ? AppTheme.accent
                      : (isDark
                          ? AppTheme.darkSubtext
                          : AppTheme.lightSubtext),
                ),
                const SizedBox(width: 4),
                Text(
                  fmt.format(task.deadline),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUrgent && !task.completed
                        ? AppTheme.accent
                        : (isDark
                            ? AppTheme.darkSubtext
                            : AppTheme.lightSubtext),
                    fontWeight: isUrgent && !task.completed
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (isUrgent && !task.completed) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(31),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SEGERA',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
                const Icon(Icons.delete_outline,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                const Text('Hapus',
                    style: TextStyle(color: AppTheme.accent)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
