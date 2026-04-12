/// Constantes globales de la app Cosecha.
class AppConstants {
  AppConstants._();

  // ── App ──
  static const String appName = 'Cosecha';
  static const String orgName = 'En Copa de Balón';
  static const String orgShort = 'ECDB';

  // ── GPS ──
  static const int defaultRadioPermitido = 100; // metros
  static const int gpsTimeoutSeconds = 10;
  static const int gpsMaxAge = 0;
  static const double gpsDesiredAccuracy = 50.0; // metros

  // ── Fichaje ──
  static const int fichajeRetentionYears = 4; // RD-ley 8/2019
  static const int standardWeeklyHours = 40;
  static const int breakRequiredAfterHours = 6;
  static const int reminderMinutesBefore = 15;

  // ── PIN ──
  static const int pinLength = 4;

  // ── Offline Sync ──
  static const int syncRetryMaxAttempts = 5;
  static const int syncRetryBaseDelayMs = 2000;

  // ── Timeouts ──
  static const int apiTimeoutSeconds = 15;

  // ── UI ──
  static const double cardBorderRadius = 14.0;
  static const double modalBorderRadius = 20.0;
  static const double fabBorderRadius = 28.0;
  static const double spacingUnit = 8.0;

  // ── Roles ──
  static const String rolAdmin = 'admin';
  static const String rolManager = 'manager';
  static const String rolEmpleado = 'empleado';
  static const String rolComercial = 'comercial';

  // ── Fichaje métodos ──
  static const String metodoApp = 'app';
  static const String metodoQr = 'qr';
  static const String metodoManual = 'manual';
}
