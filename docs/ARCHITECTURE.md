# 🏛️ Courtify - Master Architecture & Technical Design Document

This document outlines the systematic design, architectural patterns, and execution strategy for **Courtify**, a production-ready Court Booking application built with Flutter & Riverpod.

---

## 🏗️ 1. Full Architecture Explanation (Clean Architecture)

We strictly follow the **Clean Architecture** paradigm to assure Separation of Concerns, highly testable code, and offline-first robustness. The application is divided into 4 main layers:

### A. Presentation Layer
- **Components**: Flutter Screens, Widgets, and Riverpod Providers (`StateNotifierProvider`, `AsyncNotifierProvider`).
- **Responsibility**: Exclusively manages UI and user interactions. State is received asynchronously from Riverpod Providers, maintaining reactive UI binding without business logic.

### B. Application Layer (Notifiers / UseCases)
- **Components**: UseCases (optional) or directly Riverpod Controllers.
- **Responsibility**: Orchestrates interactions between the UI and Domain layers. It translates Domain Models into UI States. Executing business rules by calling the repositories.

### C. Domain Layer
- **Components**: Entities, Repositories Interfaces (`ICourtRepository`), Failure/Exception definitions.
- **Responsibility**: The innermost layer. It encapsulates pure business rules and data definitions independent of Flutter, Supabase, or SQLite. 
- *Rule examples:* `canCancelBooking(DateTime playTime)` logically sits here.

### D. Data Layer
- **Components**: 
  - **Models** (DTOs handling JSON serialization), 
  - **Data Sources** (`RemoteDataSource` for Supabase, `LocalDataSource` for SQLite/sqflite), 
  - **Repository Implementations** (`CourtRepositoryImpl`).
- **Responsibility**: Handles all Network and DB operations. The Repository implementation bridges the Local and Remote sources to achieve the offline-first synchronization strategy.

---

## 📂 2. Folder Structure

```text
lib/
├── core/                       # Shared utilities, constants, themes
│   ├── constants/              # App strings, colors, api keys
│   ├── error/                  # Failure classes (ServerFailure, CacheFailure)
│   ├── network/                # Internet connection checker
│   └── utils/                  # Formatters, Validators (e.g. DateFormatters)
├── domain/                     # Core business logic (No Flutter dependencies)
│   ├── entities/               # User, Court, Booking, TimeSlot
│   ├── repositories/           # Abstract classes (IAuthRepository)
│   └── usecases/               # Granular actions (e.g. CancelBookingUseCase)
├── data/                       # Data retrieval & caching
│   ├── models/                 # UserModel, CourtModel (with fromJson/toJson)
│   ├── datasources/
│   │   ├── local/              # SQLite DB Service (sqflite)
│   │   └── remote/             # Supabase Client wrapper
│   └── repositories/           # Implementations of Domain repositories
├── presentation/               # UI and State Management
│   ├── features/
│   │   ├── auth/               # Login, Register, Profile
│   │   │   ├── providers/      # AuthNotifier (Riverpod)
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── booking/            # Booking flow, history
│   │   │   ├── providers/
│   │   │   └── screens/
│   │   ├── court/              # Court discovery, details, management
│   │   ├── payment/
│   ├── shared/                 # Shared widgets (CustomButton, CustomTextField)
│   └── theme/
└── main.dart                   # Entry point, ProviderScope initialization
```

---

## 🔄 3. Riverpod Skeleton Code

We use Riverpod for Dependency Injection and State Management. Here is the skeleton mapping:

*   **`auth_provider.dart`**: Manages Login/Logout state.
*   **`court_provider.dart`**: Fetches courts based on location/search. Uses `AsyncValue` to handle Loading/Error/Data states.
*   **`booking_provider.dart`**: Manages the booking cart, submission, and history. Contains methods like `submitBooking()`.

*Check `lib/presentation/features/` in your source code for the generated skeleton codes.*

---

## ⚖️ 4. Business Rule Enforcement Code

Business rules are placed safely inside Domain entities or UseCases.

```dart
// domain/entities/booking.dart
class BookingEntity {
  // ... parameters

  /// Rule: Cancel allowed only if >= 2 hours before play time
  bool get canBeCancelled {
    if (status == 'completed' || status == 'cancelled') return false;
    
    final now = DateTime.now();
    final playDateTime = DateTime(
      bookDate.year, 
      bookDate.month, 
      bookDate.day, 
      startTime.hour, 
      startTime.minute
    );
    
    return playDateTime.difference(now).inHours >= 2;
  }
}
```

---

## 📡 5. Offline-First Sync Strategy Diagram

The system guarantees operations without an internet connection using an SQLite Cache + Background Sync queue.

```text
  [ User Actions Booking ]
           |
           v
  [ Repository implementation receives Booking Request ]
           |
           v
  [ Saves to SQLite 'local_bookings' with synced = 0 ] ---> (Returns Success UI instantly)
           |
           v
  [ Background Sync Service OR Network Connectivity Listener ]
           |
  (Device goes Online)
           |
           v
  [ Query SQLite: SELECT * FROM local_bookings WHERE synced = 0 ]
           |
           v
  [ Push queue to Supabase ]
           |
    +------+------+
    |             |
[ Success ]   [ Failure (e.g. Double Booking / Conflict) ]
    |             |
    v             v
[ SQLite: ]   [ SQLite: ]
[ synced=1]   [ synced=2] --> Notify user of conflict to resolve manually
```

---

## 🧪 6. Testing Strategy

1.  **Unit Tests (Business Logic)**: We test the UseCases and Entities without Flutter context (pure Dart). Mockito/Mocktail is used to mock Repositories.
2.  **Widget Tests**: We spin up individual screens (like the `BookingScreen`) wrapping them in a `ProviderScope` with overridden mock providers to simulate user taps and UI state changes.

---

## 🚀 7. Deployment Instructions

### A. Pre-flight Checks
1. Update version in `pubspec.yaml` (e.g. `version: 1.0.0+1`).
2. Ensure no lint warnings: `flutter analyze`.

### B. Android Build (Release)
Run the following commands for performance optimization and bundle creation:
```bash
# Clean project
flutter clean
flutter pub get

# Generate App Bundle for Play Store
flutter build appbundle --release --obfuscate --split-debug-info=./debug_info

# Build standalone APK for direct installation/testing
flutter build apk --release --split-per-abi
```

### C. iOS Build (Release)
```bash
# iOS preparation
cd ios && pod install && cd ..

# Build standard iOS Archive
flutter build ipa --release --obfuscate --split-debug-info=./debug_info
```

### D. Performance Profiling
To test Jank/Stutter on actual devices before releasing:
```bash
flutter run --profile
# Use DevTools embedded link to track frame rendering time < 16ms
```
