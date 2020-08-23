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
              FlatButton(
                onPressed: () async {
                  var init = await Sumup.init(affiliateKey);
                  print(init);
                },
                child: Text('Init'),
              ),
              FlatButton(
                onPressed: () async {
                  var login = await Sumup.login();
                  print(login);
                },
                child: Text('Login'),
              ),
              FlatButton(
                onPressed: () async {
                  var settings = await Sumup.openSettings();
                  print(settings);
                },
                child: Text('Open settings'),
              ),
              FlatButton(
                onPressed: () async {
                  var payment = SumupPayment(
                    title: 'Test payment',
                    total: 1.2,
                    currency: 'EUR',
                    foreignTransactionId: '',
                    saleItemsCount: 0,
                    skipSuccessScreen: false,
                    tip: .0,
                  );

                  var request = SumupPaymentRequest(payment, info: {
                    'AccountId': 'taxi0334',
                    'From': 'Paris',
                    'To': 'Berlin',
                  });

                  var checkout = await Sumup.checkout(request);
                  print(checkout);
                },
                child: Text('Checkout'),
              ),
              FlatButton(
                onPressed: () async {
                  var isLogged = await Sumup.isLoggedIn;
                  print(isLogged);
                },
                child: Text('Is logged in'),
              ),
              FlatButton(
                onPressed: () async {
                  var isInProgress = await Sumup.isCheckoutInProgress;
                  print(isInProgress);
                },
                child: Text('Is checkout in progress'),
              ),
              FlatButton(
                onPressed: () async {
                  var merchant = await Sumup.merchant;
                  print(merchant);
                },
                child: Text('Current merchant'),
              ),
              FlatButton(
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
