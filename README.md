# sumup

[![pub package](https://img.shields.io/pub/v/sumup.svg)](https://pub.dev/packages/sumup) [![likes](https://badges.bar/sumup/likes)](https://pub.dev/packages/sumup/score) [![popularity](https://badges.bar/sumup/popularity)](https://pub.dev/packages/sumup/score)  [![pub points](https://badges.bar/sumup/pub%20points)](https://pub.dev/packages/sumup/score)

A Flutter wrapper to use the SumUp SDK.

With this plugin, your app can easily connect to a SumUp terminal,
login and accept card payments on Android and iOS.

## Prerequisites

1) Registered for a merchant account via SumUp's [country websites](https://sumup.it/purplesoft) (or received a test account).
2) Received SumUp card terminal: Air, Air Lite, PIN+ terminal, Chip & Signature reader, or SumUp Air Register.
3) Requested an Affiliate (Access) Key and registered your application ID via [SumUp Dashboard](https://me.sumup.com/developers) for Developers.
4) Deployment Target iOS 10.0 or higher.
5) Android minSdkVersion 21 or higher.

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

Init SumUp SDK:

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