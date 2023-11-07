import 'package:flutter/material.dart';
import 'package:sumup/sumup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String affiliateKey = 'your-affiliate-key';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sumup plugin'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  var init = await Sumup.init(affiliateKey);
                  print(init);
                },
                child: Text('Init'),
              ),
              TextButton(
                onPressed: () async {
                  var login = await Sumup.login();
                  print(login);
                },
                child: Text('Login'),
              ),
              TextButton(
                onPressed: () async {
                  var login = await Sumup.loginWithToken('your-token');
                  print(login);
                },
                child: Text('Login with token'),
              ),
              TextButton(
                onPressed: () async {
                  var settings = await Sumup.openSettings();
                  print(settings);
                },
                child: Text('Open settings'),
              ),
              TextButton(
                onPressed: () async {
                  var prepare = await Sumup.prepareForCheckout();
                  print(prepare);
                },
                child: Text('Prepare for checkout'),
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
                  );

                  var request = SumupPaymentRequest(payment);
                  var checkout = await Sumup.checkout(request);
                  print(checkout);
                },
                child: Text('Checkout'),
              ),
              TextButton(
                onPressed: () async {
                  var isLogged = await Sumup.isLoggedIn;
                  print(isLogged);
                },
                child: Text('Is logged in'),
              ),
              TextButton(
                onPressed: () async {
                  var isInProgress = await Sumup.isCheckoutInProgress;
                  print(isInProgress);
                },
                child: Text('Is checkout in progress'),
              ),
              TextButton(
                onPressed: () async {
                  var isTcrAvailable = await Sumup.isTipOnCardReaderAvailable;
                  print(isTcrAvailable);
                },
                child: Text('Is TCR available'),
              ),
              TextButton(
                onPressed: () async {
                  var merchant = await Sumup.merchant;
                  print(merchant);
                },
                child: Text('Current merchant'),
              ),
              TextButton(
                onPressed: () async {
                  var logout = await Sumup.logout();
                  print(logout);
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
