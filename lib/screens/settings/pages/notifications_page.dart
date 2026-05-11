import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.downloadOngoingNotifications,
    required this.downloadCompletedNotifications,
    required this.onDownloadOngoingNotificationsChanged,
    required this.onDownloadCompletedNotificationsChanged,
  });

  final bool downloadOngoingNotifications;
  final bool downloadCompletedNotifications;
  final ValueChanged<bool> onDownloadOngoingNotificationsChanged;
  final ValueChanged<bool> onDownloadCompletedNotificationsChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late bool _downloadOngoingNotifications;
  late bool _downloadCompletedNotifications;

  @override
  void initState() {
    super.initState();
    _downloadOngoingNotifications = widget.downloadOngoingNotifications;
    _downloadCompletedNotifications = widget.downloadCompletedNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Download alerts'),
                    _buildCard(),
                    _buildScanDivider(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A26))),
      ),
      child: Row(
        children: [
          _CpBackButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Notifications',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.shareTechMono(
                fontSize: 20,
                color: accentPrimary,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        '// ${label.toUpperCase()}',
        style: GoogleFonts.shareTechMono(
          fontSize: 10,
          color: accentPrimary.withValues(alpha: 0.65),
          letterSpacing: 2.2,
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D16),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E30)),
          right: BorderSide(color: Color(0xFF1E1E30)),
          bottom: BorderSide(color: Color(0xFF1E1E30)),
          left: BorderSide(color: accentPrimary, width: 3),
        ),
      ),
      child: Column(
        children: [
          _CpNotifRow(
            icon: Icons.downloading_rounded,
            title: 'Download ongoing\nnotification',
            subtitle: 'Show progress while songs are downloading',
            value: _downloadOngoingNotifications,
            isCyan: false,
            onChanged: (v) {
              setState(() => _downloadOngoingNotifications = v);
              widget.onDownloadOngoingNotificationsChanged(v);
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF141420)),
          _CpNotifRow(
            icon: Icons.download_done_rounded,
            title: 'Download completed\nnotification',
            subtitle: 'Show heads-up alert when all downloads finish',
            value: _downloadCompletedNotifications,
            isCyan: true,
            onChanged: (v) {
              setState(() => _downloadCompletedNotifications = v);
              widget.onDownloadCompletedNotificationsChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedLinePainter(
          color: accentPrimary.withValues(alpha: 0.15),
        ),
      ),
    );
  }

}

// ── Notification row ──────────────────────────────────────────────────────────

class _CpNotifRow extends StatelessWidget {
  const _CpNotifRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isCyan,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isCyan;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = isCyan ? accentCyan : accentPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CpIconBox(icon: icon, accent: accent, isCyan: isCyan),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCyan ? accentCyan : const Color(0xFFE0D5B0),
                    letterSpacing: 1.0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 11,
                    color: const Color(0xFF555570),
                    letterSpacing: 0.4,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _CpToggle(value: value, isCyan: isCyan, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _CpIconBox extends StatelessWidget {
  const _CpIconBox({
    required this.icon,
    required this.accent,
    required this.isCyan,
  });

  final IconData icon;
  final Color accent;
  final bool isCyan;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _ParallelogramClipper(slant: 5),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isCyan ? const Color(0xFF001820) : const Color(0xFF12120E),
          border: Border.all(color: accent),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
    );
  }
}

// ── Custom toggle ─────────────────────────────────────────────────────────────

class _CpToggle extends StatelessWidget {
  const _CpToggle({
    required this.value,
    required this.isCyan,
    required this.onChanged,
  });

  final bool value;
  final bool isCyan;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = isCyan ? accentCyan : accentPrimary;
    final trackBg = value
        ? (isCyan ? const Color(0xFF001820) : const Color(0xFF1A1200))
        : const Color(0xFF1A1A26);
    final borderColor = value ? accent : const Color(0xFF2A2A40);
    final thumbColor = value ? accent : const Color(0xFF2A2A40);

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: const _ParallelogramClipper(slant: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 26,
              decoration: BoxDecoration(
                color: trackBg,
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: value ? 23 : 3,
                    top: 3,
                    child: ClipPath(
                      clipper: const _ParallelogramClipper(slant: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 18,
                        height: 18,
                        color: thumbColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.shareTechMono(
              fontSize: 9,
              letterSpacing: 1.1,
              color: value ? accent : const Color(0xFF3A3A55),
            ),
            child: Text(value ? 'ON' : 'OFF'),
          ),
        ],
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _CpBackButton extends StatelessWidget {
  const _CpBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const _ParallelogramClipper(slant: 6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: accentPrimary),
          ),
          child: const Icon(Icons.chevron_left, color: accentPrimary, size: 20),
        ),
      ),
    );
  }
}

// ── Parallelogram clipper ─────────────────────────────────────────────────────

class _ParallelogramClipper extends CustomClipper<Path> {
  const _ParallelogramClipper({required this.slant});

  final double slant;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(slant, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width - slant, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_ParallelogramClipper old) => old.slant != slant;
}

// ── Dashed line painter ───────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
