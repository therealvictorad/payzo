# Payzo

A full-stack fintech mobile application built with **Flutter** and **Laravel**, featuring real-time wallet management, Paystack payment integration, airtime top-up, bill payments, virtual cards, and payment links.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x + Riverpod |
| Backend | Laravel 11 + Sanctum |
| Payments | Paystack |
| Database | MySQL |
| Storage | Flutter Secure Storage + SharedPreferences |

---

## Features & Implementation Status

| Feature | Status | Notes |
|---|---|---|
| Authentication | ✅ Live | Register, login, logout via Laravel Sanctum |
| Wallet Balance | ✅ Live | Real-time balance fetch and animated display |
| Send Money | ✅ Live | Instant wallet-to-wallet transfer by email |
| Fund Wallet | ✅ Live | Paystack WebView + webhook + balance credit |
| Transaction History | ✅ Live | Paginated, real data from database |
| Payment Links | ✅ Live | Create, share, and pay links — wallets debit/credit correctly |
| Airtime Top-up | ⚠️ Simulated | Wallet is debited and transaction is recorded, but no real airtime provider (e.g. VTPass) is integrated — no actual airtime is sent |
| Bill Payments | ⚠️ Simulated | Wallet is debited and transaction is recorded, but no real bill provider API is called — no actual bill is paid |
| Virtual Cards | ⚠️ Simulated | Card records are created in the database with generated details, but no real card issuer (e.g. Sudo, Stripe Issuing) is integrated |
| Dark / Light Mode | ✅ Live | Persisted via SharedPreferences |
| Profile Avatar | ✅ Live | Camera and gallery photo picker, persisted locally |

---

## Project Structure

```
sendr/
├── payzo-mobile/        # Flutter app
│   ├── lib/
│   │   ├── core/        # Theme, routes, constants
│   │   ├── models/      # Data models
│   │   ├── providers/   # Riverpod state management
│   │   ├── screens/     # All app screens
│   │   ├── services/    # API service layer
│   │   └── widgets/     # Reusable widgets
│   └── android/ios/     # Platform configs
│
└── payzo-web/           # Laravel backend
    ├── app/
    │   ├── Http/Controllers/
    │   ├── Models/
    │   └── Services/
    ├── routes/api.php
    └── database/migrations/
```

---

## Payment Flow

```
User taps "Fund Wallet"
       ↓
Flutter → POST /api/payments/initialize
       ↓
Laravel → Paystack API (initialize transaction)
       ↓
Paystack returns authorization_url + reference
       ↓
Flutter opens Paystack WebView
       ↓
User completes payment
       ↓
Paystack → POST /api/payments/webhook (charge.success)
       ↓
Laravel verifies HMAC signature → credits wallet
       ↓
Flutter verifies via GET /api/payments/verify/{reference}
       ↓
Wallet balance updates automatically
```

---

## Getting Started

### Backend (Laravel)

```bash
cd payzo-web
composer install
cp .env.example .env
php artisan key:generate
```

Update `.env`:
```env
DB_DATABASE=payzo
DB_USERNAME=root
DB_PASSWORD=

PAYSTACK_SECRET_KEY=sk_test_your_key_here
PAYSTACK_PUBLIC_KEY=pk_test_your_key_here
```

```bash
php artisan migrate
php artisan serve
```

### Flutter App

```bash
cd payzo-mobile
flutter pub get
flutter run
```

> For Android emulator, the backend URL is pre-configured as `http://10.0.2.2:8000/api`.
> Update `lib/core/constants.dart` for a real device or production URL.

---

## To Make Airtime, Bills & Virtual Cards Fully Live

These features are UI and backend complete — they just need a third-party provider plugged in:

| Feature | Suggested Provider |
|---|---|
| Airtime / Data | [VTPass](https://vtpass.com) / [Nellobytes](https://nellobytes.com) |
| Bill Payments | [VTPass](https://vtpass.com) / [BuyPower](https://buypower.ng) |
| Virtual Cards | [Sudo Africa](https://sudo.africa) / [Stripe Issuing](https://stripe.com/issuing) |

Each service in `payzo-web/app/Services/` (`TopupService.php`, `BillService.php`, `VirtualCardService.php`) has a clear integration point where the provider API call should be added.

---

## Security

- All API routes are protected via Laravel Sanctum
- Paystack webhook validates HMAC-SHA512 signature
- Wallet credits use database-level `lockForUpdate` to prevent race conditions
- Auth tokens stored in Flutter Secure Storage (not SharedPreferences)
- No API keys exposed in the Flutter frontend

---

## Screenshots

> Coming soon

---

## License

MIT
