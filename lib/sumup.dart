import 'models/sumup_payment_request.dart';
import 'models/sumup_plugin_checkout_response.dart';
import 'models/sumup_plugin_merchant_response.dart';
import 'models/sumup_plugin_response.dart';
import 'models/tap_to_pay_availability.dart';
import 'src/sumup_platform_interface.dart';

export 'models/sumup_payment.dart';
export 'models/sumup_payment_request.dart';
export 'models/sumup_plugin_checkout_response.dart';
export 'models/sumup_plugin_merchant_response.dart';
export 'models/sumup_plugin_response.dart';
export 'models/sumup_product.dart';
export 'models/tap_to_pay_availability.dart';

/// Flutter wrapper for the SumUp SDK.
///
/// With this plugin, your app can easily connect to a SumUp terminal, login,
/// and accept card payments on Android and iOS. Supports card reader and
/// Tap-to-Pay checkout.
class Sumup {
  Sumup._();

  static SumupPlatform get _platform => SumupPlatform.instance;

  /// Whether the SumUp SDK has been initialized.
  static bool get isInitialized => _platform.isInitialized;

  static void _throwIfNotInitialized() {
    if (!_platform.isInitialized) {
      throw StateError('SumUp SDK is not initialized. Call Sumup.init(affiliateKey) first.');
    }
  }

  static Future<void> _requireLogin() async {
    _throwIfNotInitialized();
    final isLogged = await isLoggedIn;
    if (isLogged == null || !isLogged) {
      throw StateError('Not logged in. Call Sumup.login() first.');
    }
  }

  /// Initializes SumUp SDK with your [affiliateKey].
  ///
  /// Must be called only once before anything else. Calling this again has no effect since
  /// the SDK has already been initialized.
  static Future<SumupPluginResponse> init(String affiliateKey) async {
    if (_platform.isInitialized) {
      return SumupPluginResponse.fromMap({
        'methodName': 'initSDK',
        'status': true,
        'message': {'initialized': true},
      });
    }
    return _platform.init(affiliateKey);
  }

  /// Shows SumUp login dialog.
  static Future<SumupPluginResponse> login() async {
    _throwIfNotInitialized();
    return _platform.login();
  }

  /// Uses Transparent authentication to login to SumUp SDK with supplied token.
  static Future<SumupPluginResponse> loginWithToken(String token) async {
    _throwIfNotInitialized();
    return _platform.loginWithToken(token);
  }

  /// Returns whether merchant is already logged in.
  static Future<bool?> get isLoggedIn async {
    _throwIfNotInitialized();
    return _platform.isLoggedIn;
  }

  /// Returns the current merchant.
  static Future<SumupPluginMerchantResponse> get merchant async {
    await _requireLogin();
    return _platform.merchant;
  }

  /// Opens SumUp dialog to connect to a card terminal.
  static Future<SumupPluginResponse> openSettings() async {
    await _requireLogin();
    return _platform.openSettings();
  }

  /// Wakes up the card terminal before checkout. Deprecated, use [prepareForCheckout] instead.
  @Deprecated('Use prepareForCheckout() instead')
  static Future<SumupPluginResponse> wakeUpTerminal() => prepareForCheckout();

  /// Speeds up checkout time by waking the card terminal in advance.
  static Future<SumupPluginResponse> prepareForCheckout() async {
    await _requireLogin();
    return _platform.prepareForCheckout();
  }

  /// Checks if Tip on Card Reader (TCR) feature is available.
  static Future<bool> get isTipOnCardReaderAvailable async {
    await _requireLogin();
    return _platform.isTipOnCardReaderAvailable;
  }

  /// Checks if card type is required in checkout (iOS only, Android returns false).
  static Future<bool> get isCardTypeRequired async {
    await _requireLogin();
    return _platform.isCardTypeRequired;
  }

  /// Checks whether Tap-to-Pay is available and activated for the current merchant.
  static Future<TapToPayAvailabilityResult> checkTapToPayAvailability() async {
    await _requireLogin();
    return _platform.checkTapToPayAvailability();
  }

  /// Presents Tap-to-Pay activation UI (iOS only).
  static Future<SumupPluginResponse> presentTapToPayActivation() async {
    await _requireLogin();
    return _platform.presentTapToPayActivation();
  }

  /// Starts a checkout with [paymentRequest].
  ///
  /// Validation of `tip` vs `tipOnCardReader` mutual exclusion is handled
  /// by [SumupPayment]'s constructor assert.
  static Future<SumupPluginCheckoutResponse> checkout(
      SumupPaymentRequest paymentRequest) async {
    await _requireLogin();
    return _platform.checkout(paymentRequest);
  }

  /// Checks if a checkout is currently in progress (iOS only, Android returns false).
  static Future<bool?> get isCheckoutInProgress async {
    await _requireLogin();
    return _platform.isCheckoutInProgress;
  }

  /// Performs logout.
  static Future<SumupPluginResponse> logout() async {
    _throwIfNotInitialized();
    return _platform.logout();
  }

  /// Checks if a card reader is currently connected (Android v7+, iOS v7+).
  static Future<bool> isCardReaderConnected() => _platform.isCardReaderConnected();

  /// Returns saved card reader details (Android v7+).
  static Future<SumupPluginResponse> getSavedCardReaderDetails() =>
      _platform.getSavedCardReaderDetails();

  /// Returns the most recent card reader status (iOS v7+).
  static Future<SumupPluginResponse> lastReaderStatus() => _platform.lastReaderStatus();
}
