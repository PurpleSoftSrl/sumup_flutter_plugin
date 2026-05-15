import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sumup/sumup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final String affiliateKey = 'your-affiliate-key';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumup plugin'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        children: [
          TextButton(
            onPressed: () async {
              var init = await Sumup.init(affiliateKey);
              print(init);
            },
            child: const Text('Init'),
          ),
          TextButton(
            onPressed: () async {
              var login = await Sumup.login();
              print(login);
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () async {
              var login = await Sumup.loginWithToken('your-access-token');
              print(login);
            },
            child: const Text('Login with token'),
          ),
          TextButton(
            onPressed: () async {
              var settings = await Sumup.openSettings();
              print(settings);
            },
            child: const Text('Open settings'),
          ),
          TextButton(
            onPressed: () async {
              var prepare = await Sumup.prepareForCheckout();
              print(prepare);
            },
            child: const Text('Prepare for checkout'),
          ),
          TextButton(
            onPressed: () async {
              var payment = SumupPayment(
                title: 'Test payment',
                total: 1.2,
                currency: 'EUR',
                foreignTransactionId: '',
                saleItemsCount: 0,
                skipSuccessScreen: false,
                skipFailureScreen: true,
                tipOnCardReader: true,
                customerEmail: null,
                customerPhone: null,
                cardType: null,
              );

              var request = SumupPaymentRequest(payment);
              var checkout = await Sumup.checkout(request);
              print(checkout);
              if (context.mounted) {
                final productsText = checkout.products != null && checkout.products!.isNotEmpty
                    ? '\n\nProducts:\n' +
                        checkout.products!
                            .map((p) => '- ${p.name} x${p.quantity} @ ${p.price}')
                            .join('\n')
                    : '';
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(checkout.success == true ? 'Checkout OK' : 'Checkout fallito'),
                    content: SingleChildScrollView(
                      child: Text(checkout.toString() + productsText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Checkout (card reader)'),
          ),
          TextButton(
            onPressed: () async {
              var isLogged = await Sumup.isLoggedIn;
              print(isLogged);
            },
            child: const Text('Is logged in'),
          ),
          TextButton(
            onPressed: () async {
              var isInProgress = await Sumup.isCheckoutInProgress;
              print(isInProgress);
            },
            child: const Text('Is checkout in progress'),
          ),
          TextButton(
            onPressed: () async {
              var isTcrAvailable = await Sumup.isTipOnCardReaderAvailable;
              print(isTcrAvailable);
            },
            child: const Text('Is TCR available'),
          ),
          TextButton(
            onPressed: () async {
              var isCardTypeRequired = await Sumup.isCardTypeRequired;
              print(isCardTypeRequired);
            },
            child: const Text('Is Card Type Required'),
          ),
          TextButton(
            onPressed: () async {
              var merchant = await Sumup.merchant;
              print(merchant);
            },
            child: const Text('Current merchant'),
          ),
          TextButton(
            onPressed: () async {
              try {
                var availability = await Sumup.checkTapToPayAvailability();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('TTP availability'),
                      content: SingleChildScrollView(
                        child: Text(
                          'Available: ${availability.isAvailable}\n'
                          'Activated: ${availability.isActivated}'
                          '${availability.error != null ? '\n\nErrore: ${availability.error}' : ''}',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
                print(availability);
              } catch (e) {
                print(e);
                log(e.toString());
              }
            },
            child: const Text('Check TTP availability'),
          ),
          TextButton(
            onPressed: () async {
              if (Platform.isAndroid) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('TTP activation is not required on Android'),
                    ),
                  );
                }
                return;
              }
              try {
                var result = await Sumup.presentTapToPayActivation();
                print(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.status
                          ? 'Activation done'
                          : 'Failed: ${result.message}'),
                    ),
                  );
                }
              } catch (e) {
                print(e);
              }
            },
            child: const Text('Present TTP activation (iOS)'),
          ),
          TextButton(
            onPressed: () async {
              var payment = SumupPayment(
                title: 'Test TTP payment',
                total: 1.2,
                currency: 'EUR',
                foreignTransactionId: '',
                saleItemsCount: 0,
                skipSuccessScreen: false,
                skipFailureScreen: true,
                tipOnCardReader: false,
                tip: 0,
                customerEmail: null,
                customerPhone: null,
                cardType: null,
              );
              var request = SumupPaymentRequest(
                payment,
                paymentMethod: PaymentMethod.tapToPay,
              );
              try {
                var checkout = await Sumup.checkout(request);
                print(checkout);
                if (context.mounted) {
                  final isError = checkout.success == false ||
                      (checkout.errors != null && checkout.errors!.isNotEmpty);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(isError ? 'Transazione non riuscita' : 'Checkout'),
                      content: SingleChildScrollView(
                        child: Text(
                          checkout.errors != null && checkout.errors!.isNotEmpty
                              ? checkout.errors!
                              : checkout.toString(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                print(e);
                log(e.toString(), name: 'Checkout with TTP error');
              }
            },
            child: const Text('Checkout with TTP'),
          ),
          TextButton(
            onPressed: () async {
              var logout = await Sumup.logout();
              print(logout);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
