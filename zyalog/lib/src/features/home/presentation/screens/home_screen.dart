import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../schedules/models/schedule_model.dart';
import '../../../schedules/state/schedules_providers.dart';
import '../../../tasks/models/task_model.dart';
import '../../../tasks/state/tasks_providers.dart';
import '../../../tasks/state/tasks_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _hariLabel = <String, String>{
    'senin': 'Senin',
    'selasa': 'Selasa',
    'rabu': 'Rabu',
    'kamis': 'Kamis',
    'jumat': 'Jumat',
    'sabtu': 'Sabtu',
    'minggu': 'Minggu',
  };

  final DateFormat _taskDateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  bool _isWithinNext24Hours(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    return diff.inMilliseconds > 0 && diff.inHours <= 24;
  }

  Future<void> _showTaskForm({TaskModel? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    DateTime selectedDeadline = existing?.deadline ?? DateTime.now().add(const Duration(days: 1));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Tambah Tugas' : 'Edit Tugas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Mata kuliah wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Deskripsi Tugas'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tenggat'),
                      subtitle: Text(_taskDateFormat.format(selectedDeadline)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (pickedDate == null || !context.mounted) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                        );
                        if (pickedTime == null) return;
                        setModalState(() {
                          selectedDeadline = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        if (existing == null) {
                          await ref.read(tasksControllerProvider.notifier).createTask(
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                deadline: selectedDeadline,
                              );
                        } else {
                          await ref.read(tasksControllerProvider.notifier).updateTask(
                                existing.copyWith(
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim(),
                                  deadline: selectedDeadline,
                                ),
                              );
                        }

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(existing == null ? 'Tambah Tugas' : 'Simpan Perubahan'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showScheduleForm({ScheduleModel? existing}) async {
    final courseController = TextEditingController(text: existing?.mataKuliah ?? '');
    final roomController = TextEditingController(text: existing?.ruang ?? '');
    final formKey = GlobalKey<FormState>();

    String hari = existing?.hari ?? 'senin';
    String jamMulai = existing?.jamMulai ?? '07:00';
    String jamSelesai = existing?.jamSelesai ?? '08:40';

    TimeOfDay parseTime(String value) {
      final parts = value.split(':');
      final hour = int.tryParse(parts.first) ?? 7;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    String formatTimeOfDay(TimeOfDay value) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: hari,
                      items: _hariLabel.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => hari = value);
                      },
                      decoration: const InputDecoration(labelText: 'Hari'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: courseController,
                      decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Mata kuliah wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: roomController,
                      decoration: const InputDecoration(labelText: 'Ruang (opsional)'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Jam Mulai'),
                            subtitle: Text(jamMulai),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: parseTime(jamMulai),
                              );
                              if (picked == null) return;
                              setModalState(() => jamMulai = formatTimeOfDay(picked));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Jam Selesai'),
                            subtitle: Text(jamSelesai),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: parseTime(jamSelesai),
                              );
                              if (picked == null) return;
                              setModalState(() => jamSelesai = formatTimeOfDay(picked));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        if (existing == null) {
                          await ref.read(schedulesControllerProvider.notifier).createSchedule(
                                hari: hari,
                                mataKuliah: courseController.text.trim(),
                                ruang: roomController.text.trim(),
                                jamMulai: jamMulai,
                                jamSelesai: jamSelesai,
                              );
                        } else {
                          await ref.read(schedulesControllerProvider.notifier).updateSchedule(
                                existing.copyWith(
                                  hari: hari,
                                  mataKuliah: courseController.text.trim(),
                                  ruang: roomController.text.trim(),
                                  jamMulai: jamMulai,
                                  jamSelesai: jamSelesai,
                                ),
                              );
                        }

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(existing == null ? 'Tambah Jadwal' : 'Simpan Perubahan'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final tasksState = ref.watch(tasksControllerProvider);
    final schedulesState = ref.watch(schedulesControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    final tasks = tasksState.filteredTasks
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    final dueSoonTasks = tasksState.tasks
        .where((task) => !task.completed && _isWithinNext24Hours(task.deadline))
        .toList();

    final byHari = <String, List<ScheduleModel>>{};
    for (final key in _hariLabel.keys) {
      byHari[key] = <ScheduleModel>[];
    }
    for (final item in schedulesState.items) {
      byHari.putIfAbsent(item.hari, () => <ScheduleModel>[]).add(item);
    }
    for (final entry in byHari.entries) {
      entry.value.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
    }

    final isBusy =
        tasksState.isLoading || schedulesState.isLoading || authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZyaLog Mobile'),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeControllerProvider.notifier).toggleLightDark(),
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Ubah tema',
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
          ),
          IconButton(
            onPressed: isBusy ? null : () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tasksControllerProvider.notifier).loadTasks();
          await ref.read(schedulesControllerProvider.notifier).loadSchedules();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Halo, ${user?.name.isNotEmpty == true ? user!.name : 'Mahasiswa'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _TaskStatsCard(
              total: tasksState.totalTasks,
              pending: tasksState.totalTasks - tasksState.completedTasks,
              done: tasksState.completedTasks,
              progress: tasksState.completionProgress,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tugas Kuliah', style: Theme.of(context).textTheme.titleMedium),
                        FilledButton.tonalIcon(
                          onPressed: isBusy ? null : () => _showTaskForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TaskFilter>(
                      segments: const [
                        ButtonSegment(value: TaskFilter.all, label: Text('Semua')),
                        ButtonSegment(value: TaskFilter.pending, label: Text('Belum')),
                        ButtonSegment(value: TaskFilter.completed, label: Text('Selesai')),
                      ],
                      selected: {tasksState.filter},
                      onSelectionChanged: (selection) {
                        ref.read(tasksControllerProvider.notifier).setFilter(selection.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (tasksState.errorMessage != null && tasksState.errorMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          tasksState.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    if (tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Belum ada tugas tercatat.'),
                      )
                    else
                      ...tasks.map(
                        (task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: task.completed,
                            onChanged: isBusy
                                ? null
                                : (value) => ref
                                    .read(tasksControllerProvider.notifier)
                                    .toggleCompleted(task, value ?? false),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            '${task.description}\nTenggat: ${_taskDateFormat.format(task.deadline)}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            enabled: !isBusy,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showTaskForm(existing: task);
                                return;
                              }
                              if (value == 'delete') {
                                await ref.read(tasksControllerProvider.notifier).deleteTask(task.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (dueSoonTasks.isNotEmpty)
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tugas dalam 24 jam ke depan',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...dueSoonTasks.map(
                        (task) => Text('• ${task.title} - ${task.description}'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jadwal Mingguan', style: Theme.of(context).textTheme.titleMedium),
                        FilledButton.tonalIcon(
                          onPressed: isBusy ? null : () => _showScheduleForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (schedulesState.errorMessage != null && schedulesState.errorMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          schedulesState.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ..._hariLabel.entries.map((entry) {
                      final schedules = byHari[entry.key] ?? <ScheduleModel>[];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(entry.value),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: schedules.isEmpty
                            ? const [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text('Belum ada jadwal.'),
                                ),
                              ]
                            : schedules
                                .map(
                                  (item) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.mataKuliah),
                                    subtitle: Text(
                                      '${item.jamMulai} - ${item.jamSelesai}${item.ruang.isNotEmpty ? ' • ${item.ruang}' : ''}',
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      enabled: !isBusy,
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          await _showScheduleForm(existing: item);
                                          return;
                                        }
                                        if (value == 'delete') {
                                          await ref
                                              .read(schedulesControllerProvider.notifier)
                                              .deleteSchedule(item.id);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TaskStatsCard extends StatelessWidget {
  const _TaskStatsCard({
    required this.total,
    required this.pending,
    required this.done,
    required this.progress,
  });

  final int total;
  final int pending;
  final int done;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panel Tugas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(label: 'Semua', value: total),
                const SizedBox(width: 8),
                _StatChip(label: 'Belum', value: pending),
                const SizedBox(width: 8),
                _StatChip(label: 'Selesai', value: done),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}% selesai'),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
