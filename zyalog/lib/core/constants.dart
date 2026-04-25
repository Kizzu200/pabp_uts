// lib/core/constants.dart

/// Base URL untuk Next.js API — production di Vercel.
/// Flutter langsung memanggil backend yang sudah di-deploy,
const String kApiBase = 'https://pabputs.vercel.app';

/// Key hari dalam bahasa Indonesia (sama dengan Next.js)
const List<String> kHariKeys = [
  'senin',
  'selasa',
  'rabu',
  'kamis',
  'jumat',
  'sabtu',
  'minggu',
];

const Map<String, String> kHariLabel = {
  'senin': 'Senin',
  'selasa': 'Selasa',
  'rabu': 'Rabu',
  'kamis': 'Kamis',
  'jumat': 'Jumat',
  'sabtu': 'Sabtu',
  'minggu': 'Minggu',
};
