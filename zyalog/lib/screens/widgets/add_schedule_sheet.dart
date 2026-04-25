// lib/screens/widgets/add_schedule_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';

class AddScheduleSheet extends StatefulWidget {
  final ScheduleModel? editing;

  const AddScheduleSheet({super.key, this.editing});

  @override
  State<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<AddScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _hari;
  late TextEditingController _mataKuliahCtrl;
  late TextEditingController _ruangCtrl;
  late TextEditingController _jamMulaiCtrl;
  late TextEditingController _jamSelesaiCtrl;
  bool _loading = false;

  bool get isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _hari = widget.editing?.hari ?? 'senin';
    _mataKuliahCtrl =
        TextEditingController(text: widget.editing?.mataKuliah ?? '');
    _ruangCtrl = TextEditingController(text: widget.editing?.ruang ?? '');
    _jamMulaiCtrl =
        TextEditingController(text: widget.editing?.jamMulai ?? '');
    _jamSelesaiCtrl =
        TextEditingController(text: widget.editing?.jamSelesai ?? '');
  }

  @override
  void dispose() {
    _mataKuliahCtrl.dispose();
    _ruangCtrl.dispose();
    _jamMulaiCtrl.dispose();
    _jamSelesaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      ctrl.text = '$h:$m';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prov = context.read<ScheduleProvider>();
    bool ok;
    if (isEdit) {
      ok = await prov.updateSchedule(
        id: widget.editing!.id,
        hari: _hari,
        mataKuliah: _mataKuliahCtrl.text.trim(),
        ruang: _ruangCtrl.text.trim(),
        jamMulai: _jamMulaiCtrl.text.trim(),
        jamSelesai: _jamSelesaiCtrl.text.trim(),
      );
    } else {
      ok = await prov.addSchedule(
        hari: _hari,
        mataKuliah: _mataKuliahCtrl.text.trim(),
        ruang: _ruangCtrl.text.trim(),
        jamMulai: _jamMulaiCtrl.text.trim(),
        jamSelesai: _jamSelesaiCtrl.text.trim(),
      );
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error ?? 'Gagal menyimpan jadwal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              Text(
                isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 20),

              // Hari dropdown
              DropdownButtonFormField<String>(
                initialValue: _hari,
                decoration: const InputDecoration(
                  labelText: 'Hari',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                dropdownColor:
                    isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                items: kHariKeys
                    .map((k) => DropdownMenuItem(
                        value: k,
                        child: Text(kHariLabel[k]!,
                            style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText))))
                    .toList(),
                onChanged: (v) => setState(() => _hari = v!),
              ),
              const SizedBox(height: 14),

              // Mata Kuliah
              TextFormField(
                controller: _mataKuliahCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah',
                  prefixIcon: Icon(Icons.book_outlined, size: 18),
                  hintText: 'Contoh: PABP',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Ruang
              TextFormField(
                controller: _ruangCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ruang (opsional)',
                  prefixIcon: Icon(Icons.door_front_door_outlined, size: 18),
                  hintText: 'Contoh: Lab 3',
                ),
              ),
              const SizedBox(height: 14),

              // Jam
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jamMulaiCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(_jamMulaiCtrl),
                      decoration: const InputDecoration(
                        labelText: 'Jam Mulai',
                        prefixIcon: Icon(Icons.access_time, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _jamSelesaiCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(_jamSelesaiCtrl),
                      decoration: const InputDecoration(
                        labelText: 'Jam Selesai',
                        prefixIcon: Icon(Icons.access_time_filled, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : '+ Tambah Jadwal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
