# Sendr (Payzo)

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

## Features

- **Authentication** — Register, login, logout with JWT via Laravel Sanctum
- **Wallet** — Real-time balance display with animated count-up
- **Send Money** — Instant Payzo-to-Payzo transfers by email
- **Fund Wallet** — Paystack WebView payment flow with webhook verification
- **Airtime Top-up** — MTN, Airtel, Glo, 9mobile support
- **Bill Payments** — TV (DSTV, GOtv, Startimes) and Electricity
- **Payment Links** — Generate and share payment codes
- **Virtual Cards** — Create and manage virtual debit cards
- **Transaction History** — Full paginated history with status indicators
- **Dark / Light Mode** — Persisted theme preference
- **Profile Avatar** — Camera and gallery photo picker

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
