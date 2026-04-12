import 'package:intl/intl.dart';

/// Utilidades de fecha — formato español.
class CosechaDateUtils {
  CosechaDateUtils._();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
  static final _timeFormat = DateFormat('HH:mm', 'es_ES');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
  static final _dayMonthFormat = DateFormat('d MMM', 'es_ES');
  static final _fullDateFormat = DateFormat('EEEE d MMMM yyyy', 'es_ES');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);

  /// Formatea duración de trabajo (ej: "8h 30min").
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Calcula horas trabajadas entre entrada y salida.
  static Duration calcularHorasTrabajadas(DateTime entrada, DateTime salida) {
    return salida.difference(entrada);
  }

  /// Calcula horas extra (>40h semanales, ley española).
  static Duration calcularHorasExtra(List<Duration> horasDiarias) {
    final totalMinutos = horasDiarias.fold<int>(
      0,
      (sum, d) => sum + d.inMinutes,
    );
    final limiteMinutos = 40 * 60; // 40 horas en minutos
    if (totalMinutos <= limiteMinutos) return Duration.zero;
    return Duration(minutes: totalMinutos - limiteMinutos);
  }

  /// Devuelve "hace X" para timestamps recientes.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return formatDate(dateTime);
  }

  /// Primer día de la semana actual (lunes).
  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Primer día del mes actual.
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }
}
