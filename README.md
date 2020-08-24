# sumup

A Flutter wrapper to use the Sumup SDK.

With this plugin, your app can easily connect to a Sumup terminal,
login and accept card payments on Android and iOS.

## Prerequisites

1) Registered for a merchant account via SumUp's [country websites](https://sumup.com) (or received a test account).
2) Received SumUp card terminal: Air, Air Lite, PIN+ terminal, Chip & Signature reader, or SumUp Air Register.
3) Requested an Affiliate (Access) Key and registered your application ID via [SumUp Dashboard](https://me.sumup.com/developers) for Developers.
4) Deployment Target iOS 9.0 or later.

## Installing

Add sumup to your pubspec.yaml:

```yaml
dependencies:
  sumup:
```

Import sumup:

```dart
import 'package:sumup/sumup.dart';
```

## Getting Started

Init Sumup SDK:

```dart
Sumup.init(affiliateKey);
```

Login:

```dart
Sumup.login();
```

Choose your preferred terminal:

```dart
Sumup.openSettings();
```

Complete a transaction:

```dart
var payment = SumupPayment(
    title: 'Test payment',
    total: 1.2,
    currency: 'EUR',
    foreignTransactionID: '',
    saleItemsCount: 0,
    skipSuccessScreen: false,
    tip: .0,
);

var request = SumupPaymentRequest(
    payment,
    info: {
        'AccountId': 'taxi0334',
        'From': 'Paris',
        'To': 'Berlin',
    });

Sumup.checkout(request);
```

## Available APIs

```dart
Sumup.init(affiliateKey);

Sumup.login();

Sumup.isLoggedIn;

Sumup.merchant;

Sumup.openSettings();

Sumup.checkout(request);

Sumup.logout();

// iOS only
Sumup.isCheckoutInProgress;

```