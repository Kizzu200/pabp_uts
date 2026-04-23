class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://pabputs.vercel.app',
  );

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  static const String schedules = '/api/schedules';
  static const String tasks = '/api/tasks';
}
