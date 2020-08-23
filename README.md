# sumup

A Flutter wrapper to use the Sumup SDK.

With this plugin, your app can easily connect to a Sumup terminal,
login and accept card payments on Android and iOS.

# Installing

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