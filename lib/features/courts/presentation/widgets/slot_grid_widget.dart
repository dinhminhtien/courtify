import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_skeleton_widget.dart';

class SlotGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>> slots;
  final bool isLoading;

  /// Called when user confirms selection (taps "Đặt X slot" button)
  final ValueChanged<List<Map<String, dynamic>>> onConfirmSlots;
  final int columns;

  const SlotGridWidget({
    super.key,
    required this.slots,
    required this.isLoading,
    required this.onConfirmSlots,
    this.columns = 3,
  });

  @override
  State<SlotGridWidget> createState() => _SlotGridWidgetState();
}

class _SlotGridWidgetState extends State<SlotGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  final Set<String> _selectedSlotIds = {};

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(SlotGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slots != widget.slots) {
      _entranceController.reset();
      _entranceController.forward();
      // Clear selection if slots changed (e.g. date/court changed)
      setState(() => _selectedSlotIds.clear());
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Color _getBgColor(String status, bool isSelected, bool isPast) {
    if (isPast) return const Color(0xFFF0F0F0);
    if (isSelected) return AppTheme.primary;
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.slotAvailable;
      case 'HOLD':
        return AppTheme.slotHold;
      case 'BOOKED':
        return AppTheme.slotBooked;
      case 'BLOCKED':
        return AppTheme.slotBlocked;
      default:
        return AppTheme.slotBlocked;
    }
  }

  Color _getTextColor(String status, bool isSelected, bool isPast) {
    if (isPast) return const Color(0xFFBBBBBB);
    if (isSelected) return Colors.white;
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.slotAvailableText;
      case 'HOLD':
        return AppTheme.slotHoldText;
      case 'BOOKED':
        return AppTheme.slotBookedText;
      case 'BLOCKED':
        return AppTheme.slotBlockedText;
      default:
        return AppTheme.slotBlockedText;
    }
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return '$price';
  }

  /// Format time string "HH:MM:SS" or "HH:MM" → "H:MM"
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.isEmpty) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? parts[1] : '00';
    return '$hour:$minute';
  }

  /// Returns true if the slot at [index] can be selected (adjacent to current selection or first)
  bool _canSelect(int index) {
    if (_selectedSlotIds.isEmpty) return true;
    final slot = widget.slots[index];
    final slotStart = slot['startTime'] as String;
    final slotEnd = slot['endTime'] as String;

    for (final s in widget.slots) {
      if (_selectedSlotIds.contains(s['id'] as String)) {
        if ((s['endTime'] as String) == slotStart ||
            (s['startTime'] as String) == slotEnd) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns true if the slot is at the edge of the contiguous selection (can be deselected)
  bool _isEdgeSlot(String slotId) {
    if (_selectedSlotIds.length == 1) return true;
    final selected = widget.slots
        .where((s) => _selectedSlotIds.contains(s['id'] as String))
        .toList();
    selected.sort(
      (a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String),
    );
    return slotId == (selected.first['id'] as String) ||
        slotId == (selected.last['id'] as String);
  }

  /// Returns true if the slot's start time has already passed
  bool _isSlotPast(Map<String, dynamic> slot) {
    final date = slot['date'];
    if (date == null) return false;
    final slotDate = date is DateTime
        ? date
        : DateTime.tryParse(date.toString());
    if (slotDate == null) return false;
    final startTimeParts = (slot['startTime'] as String).split(':');
    if (startTimeParts.isEmpty) return false;
    final hour = int.tryParse(startTimeParts[0]) ?? 0;
    final minute = startTimeParts.length > 1
        ? (int.tryParse(startTimeParts[1]) ?? 0)
        : 0;
    final slotDateTime = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      hour,
      minute,
    );
    return slotDateTime.isBefore(DateTime.now());
  }

  void _onSlotTap(int index) {
    final slot = widget.slots[index];
    final status = slot['status'] as String;
    if (status != 'AVAILABLE') return;
    if (_isSlotPast(slot)) return;

    final slotId = slot['id'] as String;
    if (!kIsWeb) HapticFeedback.lightImpact();

    setState(() {
      if (_selectedSlotIds.contains(slotId)) {
        if (_isEdgeSlot(slotId)) {
          _selectedSlotIds.remove(slotId);
        }
      } else {
        if (_canSelect(index)) {
          _selectedSlotIds.add(slotId);
        }
      }
    });
  }

  List<Map<String, dynamic>> _getSortedSelected() {
    final selected = widget.slots
        .where((s) => _selectedSlotIds.contains(s['id'] as String))
        .toList();
    selected.sort(
      (a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String),
    );
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SlotGridSkeleton(),
      );
    }

    final selectedCount = _selectedSlotIds.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Text(
                  '${widget.slots.where((s) => s['status'] == 'AVAILABLE' && !_isSlotPast(s)).length} slot còn trống',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đã chọn $selectedCount slot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.4,
            ),
            itemCount: widget.slots.length,
            itemBuilder: (context, index) {
              final slot = widget.slots[index];
              final status = slot['status'] as String;
              final isAvailable = status == 'AVAILABLE';
              final slotId = slot['id'] as String;
              final isSelected = _selectedSlotIds.contains(slotId);
              final isPast = _isSlotPast(slot);
              final canTap = isPast
                  ? false
                  : isSelected
                  ? _isEdgeSlot(slotId)
                  : (isAvailable && _canSelect(index));
              final delay = (index * 30).clamp(0, 400);

              final startFormatted = _formatTime(slot['startTime'] as String);
              final endFormatted = _formatTime(slot['endTime'] as String);
              final timeRange = '$startFormatted - $endFormatted';

              return AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  final delayedProgress =
                      (((_entranceController.value * 600) - delay) / 200).clamp(
                        0.0,
                        1.0,
                      );
                  final curve = Curves.easeOutCubic.transform(delayedProgress);
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - curve)),
                    child: Opacity(opacity: curve, child: child),
                  );
                },
                child: _SlotTile(
                  slot: slot,
                  status: status,
                  isAvailable: isAvailable,
                  isSelected: isSelected,
                  isPast: isPast,
                  bgColor: _getBgColor(status, isSelected, isPast),
                  textColor: _getTextColor(status, isSelected, isPast),
                  formattedPrice: _formatPrice(slot['price'] as int),
                  timeRange: timeRange,
                  onTap: canTap ? () => _onSlotTap(index) : null,
                ),
              );
            },
          ),
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirmSlots(_getSortedSelected());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đặt $selectedCount slot',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatefulWidget {
  final Map<String, dynamic> slot;
  final String status;
  final bool isAvailable;
  final bool isSelected;
  final bool isPast;
  final Color bgColor;
  final Color textColor;
  final String formattedPrice;
  final String timeRange;
  final VoidCallback? onTap;

  const _SlotTile({
    required this.slot,
    required this.status,
    required this.isAvailable,
    required this.isSelected,
    required this.isPast,
    required this.bgColor,
    required this.textColor,
    required this.formattedPrice,
    required this.timeRange,
    this.onTap,
  });

  @override
  State<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends State<_SlotTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    return GestureDetector(
      onTapDown: tappable ? (_) => _pressController.forward() : null,
      onTapUp: tappable
          ? (_) {
              _pressController.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: tappable ? () => _pressController.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primary
                  : widget.textColor.withAlpha(64),
              width: widget.isSelected ? 2 : (widget.isAvailable ? 1.5 : 1),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(77),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : widget.isAvailable
                ? [
                    BoxShadow(
                      color: widget.textColor.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.timeRange,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              if (widget.isSelected)
                Icon(Icons.check_circle_rounded, size: 12, color: Colors.white)
              else if (widget.isAvailable)
                Text(
                  widget.formattedPrice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: widget.textColor.withAlpha(204),
                  ),
                )
              else if (widget.isPast)
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: widget.textColor,
                )
              else
                Icon(
                  widget.status == 'BLOCKED'
                      ? Icons.lock_outline_rounded
                      : Icons.person_outline_rounded,
                  size: 12,
                  color: widget.textColor.withAlpha(179),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
