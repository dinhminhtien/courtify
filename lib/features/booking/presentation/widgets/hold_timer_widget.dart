import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class HoldTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const HoldTimerWidget({
    super.key,
    required this.expiresAt,
    required this.onExpired,
  });

  @override
  State<HoldTimerWidget> createState() => _HoldTimerWidgetState();
}

class _HoldTimerWidgetState extends State<HoldTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.expiresAt.difference(now);
    if (diff.isNegative) {
      _timer?.cancel();
      if (mounted) widget.onExpired();
      return;
    }
    setState(() => _remaining = diff);
    if (diff.inSeconds <= 60 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isUrgent => _remaining.inSeconds <= 60;

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final color = _isUrgent ? AppTheme.error : AppTheme.warning;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isUrgent ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(102)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot đang được giữ cho bạn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: color.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isUrgent
                        ? 'Vui lòng thanh toán ngay!'
                        : 'Hoàn tất thanh toán trước khi hết giờ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: color.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
