import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/app_preferences.dart';
import '../../../theme.dart';

class AudioSourcePage extends StatefulWidget {
  const AudioSourcePage({
    super.key,
    required this.currentSource,
    required this.onSourceChanged,
  });

  final AudioSource currentSource;
  final ValueChanged<AudioSource> onSourceChanged;

  @override
  State<AudioSourcePage> createState() => _AudioSourcePageState();
}

class _AudioSourcePageState extends State<AudioSourcePage> {
  late AudioSource _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSource;
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selected = AppPreferences.readAudioSource(prefs);
    });
  }

  Future<void> _select(AudioSource source) async {
    setState(() => _selected = source);
    widget.onSourceChanged(source);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.audioSourceKey, source.name);
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
                    _buildSectionLabel('Stream source'),
                    _buildSourceCard(
                      source: AudioSource.youtube,
                      icon: Icons.play_circle_outline_rounded,
                      accentType: _AccentType.yellow,
                    ),
                    const SizedBox(height: 8),
                    _buildSourceCard(
                      source: AudioSource.jioSaavn,
                      icon: Icons.queue_music_rounded,
                      accentType: _AccentType.cyan,
                    ),
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
          Text(
            'Audio Engine',
            style: GoogleFonts.shareTechMono(
              fontSize: 20,
              color: accentPrimary,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
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

  Widget _buildSourceCard({
    required AudioSource source,
    required IconData icon,
    required _AccentType accentType,
  }) {
    final isSelected = _selected == source;
    final accent = _accentColor(accentType);
    final cardBorderLeft = isSelected ? accent : const Color(0xFF2A2A40);

    return GestureDetector(
      onTap: () => _select(source),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D16),
          border: Border(
            top: const BorderSide(color: Color(0xFF1E1E30)),
            right: const BorderSide(color: Color(0xFF1E1E30)),
            bottom: const BorderSide(color: Color(0xFF1E1E30)),
            left: BorderSide(color: cardBorderLeft, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CpIconBox(icon: icon, accentType: accentType, dim: !isSelected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label.toUpperCase(),
                      style: GoogleFonts.shareTechMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (accentType == _AccentType.yellow
                                ? const Color(0xFFE0D5B0)
                                : accent)
                            : const Color(0xFF3A3A55),
                        letterSpacing: 1.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.description,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 11,
                        color: isSelected
                            ? const Color(0xFF555570)
                            : const Color(0xFF2A2A40),
                        letterSpacing: 0.4,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _CpRadioDot(selected: isSelected, accentType: accentType),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Accent helpers ─────────────────────────────────────────────────────────────

enum _AccentType { yellow, cyan }

Color _accentColor(_AccentType t) => switch (t) {
      _AccentType.yellow => accentPrimary,
      _AccentType.cyan => accentCyan,
    };

Color _iconBgColor(_AccentType t) => switch (t) {
      _AccentType.yellow => const Color(0xFF12120E),
      _AccentType.cyan => const Color(0xFF001820),
    };

// ── Radio dot ─────────────────────────────────────────────────────────────────

class _CpRadioDot extends StatelessWidget {
  const _CpRadioDot({required this.selected, required this.accentType});

  final bool selected;
  final _AccentType accentType;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(accentType);
    return ClipPath(
      clipper: const _ParallelogramClipper(slant: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected
              ? (_AccentType.yellow == accentType
                  ? const Color(0xFF1A1200)
                  : const Color(0xFF001820))
              : const Color(0xFF1A1A26),
          border: Border.all(
            color: selected ? accent : const Color(0xFF2A2A40),
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 13, color: accent)
            : null,
      ),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _CpIconBox extends StatelessWidget {
  const _CpIconBox({
    required this.icon,
    required this.accentType,
    this.dim = false,
  });

  final IconData icon;
  final _AccentType accentType;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(accentType);
    final bg = _iconBgColor(accentType);
    return ClipPath(
      clipper: const _ParallelogramClipper(slant: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: dim ? const Color(0xFF0D0D16) : bg,
          border: Border.all(
            color: dim ? const Color(0xFF2A2A40) : accent,
          ),
        ),
        child: Icon(
          icon,
          color: dim ? const Color(0xFF2A2A40) : accent,
          size: 18,
        ),
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
