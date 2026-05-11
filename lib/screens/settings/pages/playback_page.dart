import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/app_preferences.dart';
import '../../../theme.dart';

const Color _purple = Color(0xFFB060FF);

enum _AccentType { yellow, cyan, purple }

Color _accentColor(_AccentType t) => switch (t) {
      _AccentType.yellow => accentPrimary,
      _AccentType.cyan => accentCyan,
      _AccentType.purple => _purple,
    };

Color _iconBgColor(_AccentType t) => switch (t) {
      _AccentType.yellow => const Color(0xFF12120E),
      _AccentType.cyan => const Color(0xFF001820),
      _AccentType.purple => const Color(0xFF0E0818),
    };

class PlaybackPage extends StatefulWidget {
  const PlaybackPage({
    super.key,
    required this.sessionRestore,
    required this.backgroundPlayback,
    required this.onSessionRestoreChanged,
    required this.onBackgroundPlaybackChanged,
    required this.onShowComingSoon,
  });

  final bool sessionRestore;
  final bool backgroundPlayback;
  final ValueChanged<bool> onSessionRestoreChanged;
  final ValueChanged<bool> onBackgroundPlaybackChanged;
  final ValueChanged<String> onShowComingSoon;

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  late bool _sessionRestore;
  late bool _backgroundPlayback;

  @override
  void initState() {
    super.initState();
    _sessionRestore = widget.sessionRestore;
    _backgroundPlayback = widget.backgroundPlayback;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sessionRestore = AppPreferences.readResumeOnStart(prefs);
      _backgroundPlayback = AppPreferences.readBackgroundPlayback(prefs);
    });
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
                    _buildSectionLabel('Playback config'),
                    _buildMainCard(),
                    _buildSectionLabel('Advanced'),
                    _buildAdvancedCard(),
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
          Expanded(
            child: Text(
              'Playback',
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

  Widget _buildMainCard() {
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
          _CpToggleRow(
            icon: Icons.history_rounded,
            title: 'Session restore',
            subtitle: 'Resume last track and queue when app reopens',
            value: _sessionRestore,
            accentType: _AccentType.yellow,
            onChanged: (v) {
              setState(() => _sessionRestore = v);
              widget.onSessionRestoreChanged(v);
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF141420)),
          _CpToggleRow(
            icon: Icons.headphones_outlined,
            title: 'Background playback',
            subtitle: 'Keep audio running while using other apps',
            value: _backgroundPlayback,
            accentType: _AccentType.cyan,
            onChanged: (v) {
              setState(() => _backgroundPlayback = v);
              widget.onBackgroundPlaybackChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D16),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E30)),
          right: BorderSide(color: Color(0xFF1E1E30)),
          bottom: BorderSide(color: Color(0xFF1E1E30)),
          left: BorderSide(color: accentCyan, width: 3),
        ),
      ),
      child: _CpChevronRow(
        icon: Icons.tune_rounded,
        title: 'Crossfade',
        subtitle: 'Smooth transitions between tracks',
        onTap: () => widget.onShowComingSoon('Crossfade'),
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

// ── Toggle row ────────────────────────────────────────────────────────────────

class _CpToggleRow extends StatelessWidget {
  const _CpToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentType,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final _AccentType accentType;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(accentType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CpIconBox(icon: icon, accentType: accentType),
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
                    color: accentType == _AccentType.yellow
                        ? const Color(0xFFE0D5B0)
                        : accent,
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
          _CpToggle(value: value, accentType: accentType, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Chevron row ───────────────────────────────────────────────────────────────

class _CpChevronRow extends StatelessWidget {
  const _CpChevronRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CpIconBox(icon: icon, accentType: _AccentType.purple),
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
                      color: _purple,
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
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: _purple.withValues(alpha: 0.45),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _CpIconBox extends StatelessWidget {
  const _CpIconBox({required this.icon, required this.accentType});

  final IconData icon;
  final _AccentType accentType;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(accentType);
    final bg = _iconBgColor(accentType);
    return ClipPath(
      clipper: const _ParallelogramClipper(slant: 5),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
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
    required this.accentType,
    required this.onChanged,
  });

  final bool value;
  final _AccentType accentType;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(accentType);
    final trackBg = value
        ? (accentType == _AccentType.cyan
            ? const Color(0xFF001820)
            : accentType == _AccentType.purple
                ? const Color(0xFF0E0818)
                : const Color(0xFF1A1200))
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
