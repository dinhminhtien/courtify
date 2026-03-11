// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Courtify';

  @override
  String get selectExperience => 'Chọn trải nghiệm của bạn';

  @override
  String get customer => 'Khách hàng';

  @override
  String get customerSubtitle => 'Đặt sân & quản lý lịch trình của bạn';

  @override
  String get owner => 'Chủ sân';

  @override
  String get ownerSubtitle => 'Quản lý địa điểm & lịch đặt của khách';

  @override
  String get manageBookings => 'Quản lý đặt sân';

  @override
  String get mySchedule => 'Lịch của tôi';

  @override
  String get noBookingsFound => 'Không tìm thấy lượt đặt sân nào';

  @override
  String get noBookingsYet => 'Chưa có lượt đặt sân nào.';

  @override
  String get bookCourtToStart => 'Hãy đặt sân để bắt đầu!';

  @override
  String get court => 'Sân';

  @override
  String get total => 'Tổng cộng';

  @override
  String get payment => 'Thanh toán';

  @override
  String get totalPrice => 'Tổng giá tiền';

  @override
  String get pending => 'CHỜ DUYỆT';

  @override
  String get confirmed => 'ĐÃ XÁC NHẬN';

  @override
  String get completed => 'HOÀN THÀNH';

  @override
  String get cancelled => 'ĐÃ HỦY';

  @override
  String get paid => 'ĐÃ THANH TOÁN';

  @override
  String get unpaid => 'CHƯA THANH TOÁN';

  @override
  String get markConfirmed => 'Xác nhận đặt sân';

  @override
  String get markCompleted => 'Đánh dấu hoàn thành';

  @override
  String get cancelBooking => 'Hủy đặt sân';

  @override
  String get noActionsAvailable => 'Không có hành động nào';

  @override
  String get cancelBookingDialogTitle => 'Hủy đặt sân?';

  @override
  String get cancelBookingDialogContent =>
      'Bạn có chắc chắn muốn hủy lượt đặt này không? Hành động này không thể hoàn tác và sân sẽ được giải phóng ngay lập tức.';

  @override
  String get keepIt => 'GIỮ LẠI';

  @override
  String get cancel => 'HỦY';

  @override
  String get payNow => 'THANH TOÁN NGAY';

  @override
  String get redirectingToPayment => 'Đang chuyển hướng đến VNPay / Momo...';

  @override
  String get bookingUpdated => 'Đã cập nhật lượt đặt';

  @override
  String get bookingCancelledSuccessfully => 'Đã hủy lượt đặt thành công.';

  @override
  String get cannotCompleteError =>
      'Không thể hoàn thành: Chưa đến giờ hoặc Khách chưa nhận sân (BR-O6)';

  @override
  String get bookNow => 'Đặt sân ngay';

  @override
  String get selectCourt => 'Chọn sân';

  @override
  String get selectSlot => 'Chọn giờ chơi';

  @override
  String get confirmBooking => 'Xác nhận đặt sân';

  @override
  String get bookingSuccess => 'Đặt sân thành công!';

  @override
  String get available => 'CÒN TRỐNG';

  @override
  String get maintenance => 'ĐANG BẢO TRÌ';
}
