import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/l10n/app_localizations.dart';
import 'package:courtify/presentation/features/court/providers/court_provider.dart';
import 'slot_selection_screen.dart';

class CourtSelectionScreen extends ConsumerWidget {
  const CourtSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtsAsync = ref.watch(courtsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.selectCourt, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: courtsAsync.when(
        data: (courts) => courts.isEmpty 
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courts.length,
              itemBuilder: (context, index) {
                final court = courts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.sports_tennis, color: Colors.white),
                    ),
                    title: Text(court.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(court.type ?? 'Standard'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SlotSelectionScreen(courtId: court.id, courtName: court.name),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy sân nào khả dụng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy kiểm tra lại bảng badminton_court trong Supabase',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
