import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

import './providers/payment_provider.dart';

class PaymentCallbackScreen extends ConsumerStatefulWidget {
  final Map<String, String>? queryParams;

  const PaymentCallbackScreen({super.key, this.queryParams});

  @override
  ConsumerState<PaymentCallbackScreen> createState() =>
      _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends ConsumerState<PaymentCallbackScreen> {
  bool _isProcessing = true;
  String _message = 'Đang xác nhận kết quả thanh toán...';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    final args = widget.queryParams;
    final orderCodeStr = args?['orderCode'];
    final cancelStr = args?['cancel']; 

    if (orderCodeStr == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _message = 'Không tìm thấy thông tin giao dịch.';
        });
      }
      return;
    }

    final orderCode = int.tryParse(orderCodeStr);
    if (orderCode == null) {
       if (mounted) {
        setState(() {
          _isProcessing = false;
          _message = 'Mã giao dịch không hợp lệ.';
        });
      }
      return;
    }

    // If redirected from cancelUrl, PayOS adds "?cancel=true" to the url!
    // Or we simply handle it by the route '/cancel'
    final isCancelRoute = ModalRoute.of(context)?.settings.name == AppRoutes.paymentCancel;
    if (isCancelRoute || cancelStr == 'true') {
      try {
        await ref.read(paymentProvider.notifier).cancelPayment(); // Actually it might just be orderCode
        final repo = ref.read(paymentsRepositoryProvider);
        await repo.cancelPayOSPayment(orderCode);
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _message = 'Thanh toán đã bị hủy.';
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          }
        });
      }
      return;
    }

    // Process success route
    try {
      final repo = ref.read(paymentsRepositoryProvider);
      
      // We explicitly check PayOS API via backend
      final payment = await repo.checkPaymentStatus(orderCode);
      
      if (mounted) {
        if (payment?.status == 'PAID' || payment?.status == 'COMPLETED') {
           setState(() {
             _isProcessing = false;
             _message = 'Thanh toán thành công!';
             _isSuccess = true;
           });
           
           // We can set success in the provider so the normal payment screen shows success!
           // But actually we can just redirect to booking history or a custom success widget here.
           Future.delayed(const Duration(seconds: 2), () {
             if (mounted) {
               Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bookingHistory, (route) => false);
             }
           });
           
        } else {
           setState(() {
             _isProcessing = false;
             _message = 'Thanh toán thất bại hoặc chưa hoàn tất.';
           });
           Future.delayed(const Duration(seconds: 3), () {
             if (mounted) {
               Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
             }
           });
        }
      }
    } catch (e) {
       if (mounted) {
          setState(() {
            _isProcessing = false;
            _message = 'Đã có lỗi xảy ra khi xác nhận thanh toán.';
          });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Xác nhận thanh toán'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const CircularProgressIndicator(color: AppTheme.primary)
              else
                Icon(
                  _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: _isSuccess ? AppTheme.success : AppTheme.error,
                  size: 64,
                ),
              const SizedBox(height: 24),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isProcessing ? AppTheme.primary : (_isSuccess ? AppTheme.success : AppTheme.error),
                ),
              ),
              if (!_isProcessing) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                   onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.primary,
                     foregroundColor: Colors.white,
                     minimumSize: const Size(double.infinity, 50),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                   child: const Text('Về trang chủ'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
