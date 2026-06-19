// lib/src/utils/pulse_format.dart
// Utilidades de formato compartidas por las pantallas Pulse.

/// Etiqueta amigable para cada tipo de marcación (la usada por el backend).
String marcacionLabel(String type) {
  switch (type) {
    case 'Ingreso':
      return 'Ingreso';
    case 'Inicio de Refrigerio':
      return 'Inicio de refrigerio';
    case 'Salida de Refrigerio':
      return 'Fin de refrigerio';
    case 'Salida':
      return 'Salida';
    default:
      return type;
  }
}

/// ¿La hora viene marcada como guardada solo localmente (pendiente de sync)?
bool isLocalMark(String? raw) => raw != null && raw.contains('(local)');

/// Normaliza una hora cruda ("13:02:05", "13:02 (local)") a "HH:MM".
String formatHora(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '--:--';
  var s = raw.replaceAll('(local)', '').trim();
  final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
  if (m == null) return s;
  final hh = m.group(1)!.padLeft(2, '0');
  final mm = m.group(2)!;
  return '$hh:$mm';
}

/// Minutos desde medianoche para una hora cruda; null si no se puede parsear.
int? minutesOfDay(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (m == null) return null;
  final hh = int.tryParse(m.group(1)!) ?? 0;
  final mm = int.tryParse(m.group(2)!) ?? 0;
  return hh * 60 + mm;
}

const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'set', 'oct', 'nov', 'dic'
];

/// Fecha corta en español: "Jue 19 jun".
String fechaCorta(DateTime t) {
  final dia = _dias[(t.weekday - 1) % 7];
  final mes = _meses[(t.month - 1) % 12];
  return '$dia ${t.day} $mes';
}
