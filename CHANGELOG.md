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
