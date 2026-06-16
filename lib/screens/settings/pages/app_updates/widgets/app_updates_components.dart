import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme.dart';

const Color cpTopbarLine = Color(0xFF1A1A26);
const Color cpWarmText = Color(0xFFE0D5B0);

TextStyle techStyle({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  Color color = cpWarmText,
  double spacing = 0.0,
  double? height,
}) {
  return GoogleFonts.shareTechMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        '//  ${label.toUpperCase()}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentPrimary.withValues(alpha: 0.76),
              letterSpacing: 3.2,
            ),
      ),
    );
  }
}

String formatDate(DateTime? value) {
  if (value == null) return 'Unknown';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

String formatDateTime(DateTime? value) {
  if (value == null) return 'UNKNOWN';
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}.${utc.month.toString().padLeft(2, '0')}.${utc.day.toString().padLeft(2, '0')} · ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')} UTC';
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size >= 100 || unitIndex == 0 ? 0 : 1;
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}
