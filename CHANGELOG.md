## 0.8.1

* Handle `installments` field null

## 0.8.0

* Upgrade android SDKs
* Rename wakeUpterminal -> prepareForCheckout (thanks to @gabrielsolomon)

## 0.7.0

* Upgrade native SDKs
* Add isTipOnCardReaderAvailable getter
* Add tipOnCardReader in SumupPayment

## 0.6.1

* Android: fix checkout hang when initializing SDK multiple times

## 0.6.0

* iOS: upgrade native SDK
* Android: upgrade native SDK
* Android: compileSdkVersion and targetSdkVersion 33
* Android: code cleaning

## 0.5.1

* iOS: upgrade native SDK

## 0.5.0

* Add login with token (thanks to @davidhole)

## 0.4.0

* iOS: add wakeUpTerminal
* Add customerEmail and customerPhone to autofill text fields in transaction successfull screen (Android only)
* Make required fields non nullable in SumupPayment class
* Migrate example to null safety
* Improve documentation

## 0.3.1

* Android: targetSdkVersion 31
* Android: fix wakeUpTerminal not returning

## 0.3.0

* Add skipFailureScreen
* Fix login response
* Upgrade iOS SDK

## 0.2.6

* Improve login
* Android: Upgrade SDK and gradle
* Deprecate info field in SUmupPaymentRequest 

## 0.2.5

* Fix crash when dismissing payment bottomsheet during checkout on iOS
* Fix cardLastDigits in checkout response on iOS

## 0.2.4

* Breaking change: Android minSdkVersion must be 21 or higher
* Upgraded iOS and Android native SDKs
* Improved code quality

## 0.2.3

* Fix cardType and cardLastDigits null in SumupPluginCheckoutResponse on Android

## 0.2.2

* Fix type cast in login check

## 0.2.1

* Fix request orientation landscape on Android

## 0.2.0

* Added null safety support
* Updated SumUp Sdk

## 0.1.0

* Added checks to prevent crashes from the native platforms, in particular:
    * All the functions that require the native SDK to be initialized throw an exception if the SDK is not initialized
    * All the functions that require login throw an exception if user is not logged in

## 0.0.5

* Fixed checkout parameters

## 0.0.4

* Fixed syntax error in android

## 0.0.3

* Fixed SumUpSDK version in podspec

## 0.0.2

* Fixed crash when transaction failed, improved documentation and code quality

## 0.0.1

* First release.
