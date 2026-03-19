# 🏸 Courtify - Ứng dụng Đặt Sân Cầu Lông Hiện Đại

Courtify là nền tảng di động giúp người chơi cầu lông dễ dàng tìm kiếm, đặt sân và quản lý lịch thi đấu. Ứng dụng được xây dựng với giao diện hiện đại, trải nghiệm mượt mà và tích hợp hệ thống thông báo thời gian thực.

![Onboarding Preview](assets/images/onboarding_bg.png)

## ✨ Tính năng chính

- **📱 Khám phá & Đặt sân**: Dashboard hiện đại, tìm kiếm sân nhanh chóng và quy trình đặt sân 3 bước (Chọn ngày -> Chọn sân -> Chọn khung giờ).
- **🔔 Thông báo thời gian thực**: Nhận thông báo tức thì khi có lịch đặt sân mới hoặc cập nhật trạng thái thanh toán qua Supabase Realtime.
- **💳 Thanh toán tích hợp**: Hỗ trợ thanh toán an toàn, tích hợp Webhook để cập nhật trạng thái tự động.
- **📊 Quản lý cho Chủ sân**: Dashboard riêng biệt dành cho chủ sân để theo dõi doanh thu và lịch trình sân.
- **🌑 Giao diện hiện đại**: Thiết kế lấy cảm hứng từ Dribbble với phong cách Glassmorphism, Rounded Corners và Vibrant Accents.

## 🛠️ Công nghệ sử dụng

- **Framework**: Flutter (^3.9.0)
- **State Management**: Riverpod (Notifier & AsyncNotifier)
- **Backend / Database**: Supabase (Auth, Database, Realtime, Storage, Edge Functions)
- **Typography**: Google Fonts (Plus Jakarta Sans)
- **Responsive Design**: Sizer
- **Payments**: Tích hợp PayOS Webhook

## 📁 Cấu trúc dự án (DDP Architecture)

Dự án tuân thủ kiến trúc **Data-Domain-Presentation** để đảm bảo tính mở rộng và dễ bảo trì:

```
lib/
├── core/               # Cấu hình API, Theme và Route chung
├── features/           # Các tính năng chính của ứng dụng
│   ├── auth/           # Đăng nhập, Đăng ký, Onboarding, Profile
│   ├── courts/         # Danh sách sân, Dashboard người dùng
│   ├── booking/        # Quy trình đặt sân & Lịch sử
│   ├── payment/        # Xử lý thanh toán
│   ├── notifications/  # Hệ thống thông báo thời gian thực
│   └── owner/          # Dashboard & Quản lý cho chủ sân
├── shared/             # Các widget dùng chung (Navigation, Badges, v.v.)
└── main.dart           # Điểm khởi đầu ứng dụng
```

## 🚀 Cài đặt & Chạy ứng dụng

1. **Cài đặt thư viện**:
```bash
flutter pub get
```

2. **Cấu hình môi trường**:
Tạo file `.env` ở thư mục gốc và cung cấp các thông tin sau:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. **Chạy ứng dụng**:
```bash
flutter run
```

## 📅 Lộ trình phát triển

- [x] Onboarding & Modern Dashboard
- [x] Tách biệt màn hình Trang chủ & Đặt sân
- [x] Hệ thống thông báo Realtime
- [ ] Tính năng tìm kiếm sân nâng cao (theo bản đồ)
- [ ] Tích hợp ví điện tử nội bộ

---
Built with ❤️ by Courtify Team
