# realtime_communication

A new Flutter project.

## MiomiPay local setup

1. Copy `.env.example` to `.env` and put your MiomiPay API key and webhook
   secret in `.env`. Do not put real credentials in `.env.example`.
2. Start the backend with `npm run start:server`.
3. In another terminal, run Flutter with
   `flutter run -d chrome --dart-define=MIOMIPAY_USE_BACKEND=true`.

The API key stays in the backend environment; the Flutter app only receives the
non-secret flag that enables the backend proxy. `.env` is ignored by Git.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
