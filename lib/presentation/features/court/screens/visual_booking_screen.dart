import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/domain/entities/court.dart';
import 'package:courtify/domain/entities/slot.dart';
import 'package:courtify/presentation/features/court/providers/court_provider.dart';
import 'package:courtify/presentation/features/booking/providers/booking_provider.dart';
import 'package:courtify/presentation/features/auth/providers/auth_provider.dart';
import 'package:courtify/l10n/app_localizations.dart';

class VisualBookingScreen extends ConsumerStatefulWidget {
  const VisualBookingScreen({super.key});

  @override
  ConsumerState<VisualBookingScreen> createState() => _VisualBookingScreenState();
}

class _VisualBookingScreenState extends ConsumerState<VisualBookingScreen> {
  DateTime selectedDate = DateTime.now();
  final double cellWidth = 100.0;
  final double cellHeight = 60.0;
  final double courtColumnWidth = 100.0;
  final List<String> timeSlots = List.generate(19, (index) => '${(index + 5).toString().padLeft(2, '0')}:00');

  @override
  Widget build(BuildContext context) {
    final courtsAsync = ref.watch(courtsProvider);
    final slotsAsync = ref.watch(allSlotsByDateProvider(selectedDate));


    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Đặt lịch ngày trực quan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006437),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Row(
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLegend(),
          Expanded(
            child: courtsAsync.when(
              data: (courts) => slotsAsync.when(
                data: (slots) => _buildGrid(courts, slots),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: const Color(0xFF006437),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _legendItem(Colors.white, 'Trống'),
          _legendItem(const Color(0xFFFF5252), 'Đã đặt'),
          _legendItem(Colors.grey, 'Khoá'),
          _legendItem(const Color(0xFFE040FB), 'Sự kiện'),
          TextButton(
            onPressed: () {},
            child: const Text('Xem sân & bảng giá', style: TextStyle(color: Colors.amber, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }


  Widget _buildGrid(List<Court> courts, List<Slot> slots) {
    return Column(
      children: [
        // Time Header
        Row(
          children: [
            Container(width: courtColumnWidth, height: 40, color: Colors.teal[50]),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // Sync with body
                child: Row(
                  children: timeSlots.map((time) => Container(
                    width: cellWidth,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        // Grid Body
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Labels
                Column(
                  children: courts.map((court) => Container(
                    width: courtColumnWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(court.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                // Slots Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: courts.map((court) {
                        final courtSlots = List<Slot>.from(slots.where((s) => s.courtId == court.id));
                        return Row(
                          children: timeSlots.map((timeStart) {
                            final slot = courtSlots.firstWhere(
                              (s) => s.startTime == timeStart,
                              orElse: () => Slot(
                                id: -1,
                                courtId: court.id,
                                date: selectedDate,
                                startTime: timeStart,
                                endTime: '',
                                priceTypeId: 0,
                                isLocked: true,
                              ),
                            );
                            return _buildCell(slot, court);
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(Slot slot, Court court) {
    if (slot.id == -1) {
      return Container(
        width: cellWidth,
        height: cellHeight,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), color: Colors.grey[100]),
      );
    }

    final bool isBooked = slot.isLocked; // Simplified for now, should ideally check status
    // Based on the screenshot, it seems red is "Mừng Xuân" themes
    
    return InkWell(
      onTap: !isBooked ? () => _confirmBooking(slot, court) : null,
      child: Container(
        width: cellWidth,
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: isBooked ? const Color(0xFFB71C1C) : Colors.white,
        ),
        child: isBooked 
          ? Center(child: Image.network('https://cdn0.iconfinder.com/data/icons/lunar-new-year-18/64/dragon-dance-lunar-new-year-holiday-festival-chinese-1024.png', width: 40)) // Placeholder for "Mừng Xuân" image
          : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _confirmBooking(Slot slot, Court court) {
    final l10n = AppLocalizations.of(context)!;
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.court}: ${court.name}'),
            const SizedBox(height: 8),
            Text('Thời gian: ${slot.startTime} - ${slot.endTime}'),
            if (slot.priceName != null) ...[
              const SizedBox(height: 8),
              Text('Loại: ${slot.priceName}'),
            ],
            const Divider(),
            Text(
              '${l10n.total}: ${currencyFormat.format(slot.price ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final auth = ref.read(authProvider);
              final userId = auth.userId;
              
              if (userId == null) return;

              final notifier = ref.read(bookingActionProvider.notifier);
              await notifier.createBooking(
                userId: userId,
                courtId: slot.courtId,
                slotId: slot.id,
                bookDate: slot.date,
                startTime: slot.startTime,
                endTime: slot.endTime,
                totalPrice: slot.price ?? 0,
              );

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.bookingSuccess)),
                );
              }
            },
            child: Text(l10n.confirmBooking),
          ),
        ],
      ),
    );
  }
}
