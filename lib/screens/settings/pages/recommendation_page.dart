import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../recommendations/recommendation_provider.dart';
import '../../../settings/app_preferences.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({
    super.key,
    required this.lastFmApiKey,
    required this.recommendationSeedStrategy,
    required this.onLastFmApiKeyChanged,
    required this.onRecommendationSeedStrategyChanged,
    required this.onValidateApiKey,
  });

  final String lastFmApiKey;
  final RecommendationSeedStrategy recommendationSeedStrategy;
  final ValueChanged<String> onLastFmApiKeyChanged;
  final ValueChanged<RecommendationSeedStrategy>
      onRecommendationSeedStrategyChanged;
  final Future<LastFmKeyValidation> Function(String key) onValidateApiKey;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _apiKeyController;
  late RecommendationSeedStrategy _seedStrategy;
  bool _apiKeyObscured = true;

  /// Tracks the outcome of the last validation call. `null` means we haven't
  /// checked yet (e.g. field is empty).
  LastFmKeyValidation? _apiKeyStatus;
  bool _validating = false;
  Timer? _validationDebounce;

  /// Monotonic counter used to drop the result of a validation call that
  /// was superseded by a newer one while it was in flight.
  int _validationGeneration = 0;

  static const Duration _validationDebounceDuration =
      Duration(milliseconds: 700);

  bool _dropdownOpen = false;
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.lastFmApiKey);
    _seedStrategy = widget.recommendationSeedStrategy;

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_blinkController);

    if (widget.lastFmApiKey.trim().isNotEmpty) {
      // Validate immediately so the user sees the status of the key they
      // previously saved as soon as they open the page.
      _runValidation(widget.lastFmApiKey);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _validationDebounce?.cancel();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onApiKeyChanged(String value) {
    final trimmed = value.trim();
    widget.onLastFmApiKeyChanged(trimmed);

    _validationDebounce?.cancel();

    if (trimmed.isEmpty) {
      // Drop any in-flight validation and clear the status.
      _validationGeneration++;
      setState(() {
        _apiKeyStatus = null;
        _validating = false;
      });
      return;
    }

    setState(() {
      _apiKeyStatus = null;
      _validating = true;
    });

    _validationDebounce = Timer(
      _validationDebounceDuration,
      () => _runValidation(trimmed),
    );
  }

  Future<void> _runValidation(String key) async {
    final generation = ++_validationGeneration;
    if (mounted) setState(() => _validating = true);

    final result = await widget.onValidateApiKey(key);

    // A newer keystroke (or field-clear) started another validation — drop
    // this stale result to avoid flipping the status back and forth.
    if (!mounted || generation != _validationGeneration) return;

    setState(() {
      _apiKeyStatus = result;
      _validating = false;
    });
  }

  Color _statusColor() {
    if (_validating) return const Color(0xFFF5C518);
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return const Color(0xFF00FF88);
      case LastFmKeyValidation.rejected:
        return const Color(0xFFE45858);
      case LastFmKeyValidation.networkError:
        return const Color(0xFFE0B14C);
      case LastFmKeyValidation.empty:
      case null:
        return const Color(0xFF6B6B8A);
    }
  }

  String _statusBadgeText() {
    if (_validating) return 'WAIT';
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return 'Auth OK';
      case LastFmKeyValidation.rejected:
        return 'Auth Err';
      case LastFmKeyValidation.networkError:
        return 'Net Err';
      case LastFmKeyValidation.empty:
      case null:
        return 'No Key';
    }
  }

  String _statusMessageText() {
    if (_validating) return 'Establishing link — testing handshake...';
    switch (_apiKeyStatus) {
      case LastFmKeyValidation.valid:
        return 'Key accepted — neural link established';
      case LastFmKeyValidation.rejected:
        return 'Access denied — invalid API credentials';
      case LastFmKeyValidation.networkError:
        return 'Link offline — check interface connection';
      case LastFmKeyValidation.empty:
      case null:
        return 'Key offline — generate connection key';
    }
  }

  String _getSeedStrategyLabel(RecommendationSeedStrategy strategy) {
    switch (strategy) {
      case RecommendationSeedStrategy.mixLikedRecent:
        return 'Mix: liked + recent';
      case RecommendationSeedStrategy.randomLiked:
        return 'Liked tracks only';
      case RecommendationSeedStrategy.mostRecent:
        return 'Recent plays only';
      case RecommendationSeedStrategy.currentlyPlaying:
        return 'Currently playing only';
    }
  }

  Widget _buildStatusIconWidget() {
    if (_validating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5C518)),
        ),
      );
    }
    if (_apiKeyStatus == LastFmKeyValidation.valid) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF001A08),
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFF00FF88), width: 1.5),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: Color(0xFF00FF88),
            size: 12,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF07070D),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP BAR
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: CyberpunkInputPainter(
                          borderColor: const Color(0xFFF5C518),
                          leftBorderColor: const Color(0xFFF5C518),
                          fillColor: Colors.transparent,
                          skewWidth: 6.0,
                        ),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFFF5C518),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'RECOMMENDATIONS',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF5C518),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                color: const Color(0xFF1A1A26),
              ),

              // LAST.FM SECTION
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
                child: Text(
                  '// LAST.FM CONFIGURATION',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFF5C518).withAlpha(166),
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D16),
                  border: Border(
                    left: BorderSide(color: Color(0xFFF5C518), width: 3),
                    top: BorderSide(color: Color(0xFF1E1E30)),
                    right: BorderSide(color: Color(0xFF1E1E30)),
                    bottom: BorderSide(color: Color(0xFF1E1E30)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 14, right: 14, bottom: 10),
                      child: Row(
                        children: [
                          CustomPaint(
                            painter: CyberpunkInputPainter(
                              borderColor: const Color(0xFFF5C518),
                              leftBorderColor: const Color(0xFFF5C518),
                              fillColor: const Color(0xFF12120E),
                              skewWidth: 5.0,
                            ),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: Icon(
                                  Icons.lock_open_rounded,
                                  color: Color(0xFFF5C518),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'LAST.FM API KEY',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE0D5B0),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: CustomPaint(
                        painter: CyberpunkInputPainter(
                          borderColor: const Color(0xFF2A2A40),
                          leftBorderColor: const Color(0xFFF5C518),
                          fillColor: const Color(0xFF06060E),
                          skewWidth: 4.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.only(right: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _apiKeyController,
                                  obscureText: _apiKeyObscured,
                                  obscuringCharacter: '•',
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: GoogleFonts.shareTechMono(
                                    color: const Color(0xFFE0D5B0),
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Paste your 32-character key',
                                    hintStyle: GoogleFonts.shareTechMono(
                                      color: const Color(0xFF555570),
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  onChanged: _onApiKeyChanged,
                                ),
                              ),
                              _buildStatusIconWidget(),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                                child: Icon(
                                  _apiKeyObscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF6B6B8A),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 10, right: 14, bottom: 14),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _blinkAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _validating || _apiKeyStatus == LastFmKeyValidation.valid
                                    ? _blinkAnimation.value
                                    : 1.0,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _statusColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessageText(),
                              style: GoogleFonts.shareTechMono(
                                fontSize: 11,
                                color: _statusColor(),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(),
                            ),
                            child: Text(
                              _statusBadgeText(),
                              style: GoogleFonts.shareTechMono(
                                fontSize: 9,
                                color: const Color(0xFF0A0A0F),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // AUTO-REFILL SECTION
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
                child: Text(
                  '// AUTO-REFILL STRATEGY',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFF5C518).withAlpha(166),
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D16),
                  border: Border(
                    left: BorderSide(color: Color(0xFFB060FF), width: 3),
                    top: BorderSide(color: Color(0xFF1E1E30)),
                    right: BorderSide(color: Color(0xFF1E1E30)),
                    bottom: BorderSide(color: Color(0xFF1E1E30)),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Row(
                          children: [
                            CustomPaint(
                              painter: CyberpunkInputPainter(
                                borderColor: const Color(0xFFB060FF),
                                leftBorderColor: const Color(0xFFB060FF),
                                fillColor: const Color(0xFF0E0818),
                                skewWidth: 5.0,
                              ),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: Icon(
                                    Icons.star_outline_rounded,
                                    color: Color(0xFFB060FF),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SEED STRATEGY',
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE0D5B0),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSeedStrategyLabel(_seedStrategy),
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 12,
                                      color: const Color(0xFFF5C518),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _dropdownOpen ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFFB060FF),
                                  size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_dropdownOpen) ...[
                      Container(
                        height: 1,
                        color: const Color(0xFF1A1A26),
                      ),
                      Container(
                        color: const Color(0xFF09090F),
                        child: Column(
                          children: RecommendationSeedStrategy.values.map((s) {
                            final isSelected = s == _seedStrategy;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _seedStrategy = s;
                                  _dropdownOpen = false;
                                });
                                widget.onRecommendationSeedStrategyChanged(s);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFF111120)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 48), // Align with title
                                    if (isSelected) ...[
                                      Text(
                                        '▶ ',
                                        style: GoogleFonts.shareTechMono(
                                          color: const Color(0xFFF5C518),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        _getSeedStrategyLabel(s),
                                        style: GoogleFonts.shareTechMono(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? const Color(0xFFF5C518)
                                              : const Color(0xFF555570),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // SCAN DIVIDER
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 18),
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(color: const Color(0xFFF5C518).withAlpha(38)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CyberpunkInputPainter extends CustomPainter {
  final Color borderColor;
  final Color leftBorderColor;
  final Color fillColor;
  final double skewWidth;

  CyberpunkInputPainter({
    required this.borderColor,
    required this.leftBorderColor,
    required this.fillColor,
    this.skewWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final leftPaint = Paint()
      ..color = leftBorderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(skewWidth, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - skewWidth, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final leftPath = Path()
      ..moveTo(skewWidth, 0)
      ..lineTo(0, size.height);
    canvas.drawPath(leftPath, leftPaint);
  }

  @override
  bool shouldRepaint(covariant CyberpunkInputPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.leftBorderColor != leftBorderColor ||
      oldDelegate.fillColor != fillColor;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height == 0 ? 1 : size.height
      ..style = PaintingStyle.stroke;

    double max = size.width;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + 6, 0), paint);
      startX += 12;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
