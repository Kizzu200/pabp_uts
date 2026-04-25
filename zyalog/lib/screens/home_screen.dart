// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import 'widgets/schedule_tab.dart';
import 'widgets/task_tab.dart';
import 'widgets/profile_tab.dart';
import 'widgets/add_schedule_sheet.dart';
import 'widgets/add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data saat pertama masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      context.read<ScheduleProvider>().fetchSchedules();
    });
  }

  void _showFab() {
    if (_currentIndex == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddScheduleSheet(),
      );
    } else if (_currentIndex == 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTaskSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> titles = ['Jadwal Mingguan', 'Tugas Kuliah', 'Profil'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Z',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              titles[_currentIndex],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ],
        ),
        actions: [
          // Urgent badge
          Consumer<TaskProvider>(
            builder: (_, tasks, __) {
              final urgentCount = tasks.urgentTasks.length;
              if (urgentCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$urgentCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    final urgent = tasks.urgentTasks;
                    if (urgent.isEmpty) return;
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _UrgentSheet(
                          urgent: urgent.map((t) => t.title).toList(),
                          isDark: isDark),
                    );
                  },
                ),
              );
            },
          ),
          // Theme toggle
          GestureDetector(
            onTap: () => auth.toggleTheme(),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder),
              ),
              child: Center(
                child: Text(isDark ? '☀️' : '🌙',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ScheduleTab(),
          TaskTab(),
          ProfileTab(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            activeIcon: Icon(Icons.check_box),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),

      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton(
              onPressed: _showFab,
              child: const Icon(Icons.add, size: 26),
            )
          : null,
    );
  }
}

class _UrgentSheet extends StatelessWidget {
  final List<String> urgent;
  final bool isDark;

  const _UrgentSheet({required this.urgent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tugas Segera (dalam 24 jam)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...urgent.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppTheme.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? AppTheme.darkText : AppTheme.lightText,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
