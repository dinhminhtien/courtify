import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/l10n/app_localizations.dart';
import 'package:courtify/domain/entities/slot.dart';
import 'package:courtify/presentation/features/court/providers/court_provider.dart';
import 'package:courtify/presentation/features/booking/providers/booking_provider.dart';
import 'package:courtify/presentation/features/auth/providers/auth_provider.dart';

class SlotSelectionScreen extends ConsumerStatefulWidget {
  final int courtId;
  final String courtName;

  const SlotSelectionScreen({
    super.key,
    required this.courtId,
    required this.courtName,
  });

  @override
  ConsumerState<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(slotsByCourtProvider((courtId: widget.courtId, date: selectedDate)));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${l10n.selectSlot}: ${widget.courtName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDatePicker(),
          Expanded(
            child: slotsAsync.when(
              data: (slots) => slots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Không có khung giờ nào cho ngày này',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vui lòng thử chọn ngày khác hoặc liên hệ chủ sân',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        return _buildSlotCard(slot);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1))),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => selectedDate = selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Slot slot) {
    final l10n = AppLocalizations.of(context)!;
    final bool isAvailable = !slot.isLocked;
    final bool isGoldenHour = slot.priceName == 'Golden Hour';
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return InkWell(
      onTap: isAvailable ? () => _confirmBooking(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isAvailable 
              ? (isGoldenHour ? Colors.amber[50] : Colors.white)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable 
                ? (isGoldenHour ? Colors.orange : AppColors.primary)
                : Colors.transparent,
            width: isGoldenHour ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoldenHour)
              const Icon(Icons.star, size: 14, color: Colors.orange),
            Text(
              '${slot.startTime} - ${slot.endTime}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAvailable ? AppColors.textPrimary : Colors.grey,
              ),
            ),
            Text(
              isAvailable 
                  ? '${slot.priceName}: ${currencyFormat.format(slot.price ?? 0)}'
                  : l10n.maintenance,
              style: TextStyle(
                fontSize: 11,
                color: isAvailable 
                    ? (isGoldenHour ? Colors.orange[800] : AppColors.primary)
                    : Colors.grey,
                fontWeight: isGoldenHour ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking(Slot slot) {
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
            Text('${l10n.court}: ${widget.courtName}'),
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
                Navigator.pop(context); // Back from slot selection
                Navigator.pop(context); // Back from court selection
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
