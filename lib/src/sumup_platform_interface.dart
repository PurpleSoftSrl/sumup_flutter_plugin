import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/sumup_payment_request.dart';
import '../models/sumup_plugin_checkout_response.dart';
import '../models/sumup_plugin_merchant_response.dart';
import '../models/sumup_plugin_response.dart';
import '../models/tap_to_pay_availability.dart';
import 'sumup_method_channel.dart';

/// Abstract platform interface for the SumUp SDK.
///
/// Each method corresponds to a SumUp native API call. Platform implementations
/// must override all methods to provide actual functionality.
abstract class SumupPlatform extends PlatformInterface {
  /// Creates a new platform interface with a unique token for verification.
  SumupPlatform() : super(token: _token);

  static final Object _token = Object();

  static SumupPlatform _instance = MethodChannelSumup();

  /// The current platform instance. Defaults to [MethodChannelSumup].
  static SumupPlatform get instance => _instance;

  /// Sets a custom platform instance (useful for testing).
  static set instance(SumupPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Whether the SDK has been initialized.
  bool isInitialized = false;

  /// Initializes the SumUp SDK with the given [affiliateKey].
  Future<SumupPluginResponse> init(String affiliateKey);

  /// Shows the SumUp login dialog.
  Future<SumupPluginResponse> login();

  /// Logs in using transparent authentication with a [token].
  Future<SumupPluginResponse> loginWithToken(String token);

  /// Whether the merchant is currently logged in.
  Future<bool?> get isLoggedIn;

  /// Returns details about the current merchant.
  Future<SumupPluginMerchantResponse> get merchant;

  /// Opens the SumUp card reader settings dialog.
  Future<SumupPluginResponse> openSettings();

  /// Prepares the terminal for a faster checkout experience.
  Future<SumupPluginResponse> prepareForCheckout();

  /// Whether Tip on Card Reader is available for this terminal.
  Future<bool> get isTipOnCardReaderAvailable;

  /// Whether card type selection is required during checkout (iOS only).
  Future<bool> get isCardTypeRequired;

  /// Checks Tap-to-Pay availability for the current merchant.
  Future<TapToPayAvailabilityResult> checkTapToPayAvailability();

  /// Presents the Tap-to-Pay activation flow (iOS only).
  Future<SumupPluginResponse> presentTapToPayActivation();

  /// Starts a checkout with the given [paymentRequest].
  Future<SumupPluginCheckoutResponse> checkout(SumupPaymentRequest paymentRequest);

  /// Whether a checkout is currently in progress (iOS only, Android returns false).
  Future<bool?> get isCheckoutInProgress;

  /// Logs out the current merchant session.
  Future<SumupPluginResponse> logout();

  /// Whether a card reader is currently connected (v7+).
  Future<bool> isCardReaderConnected();

  /// Returns saved card reader details (Android v7+).
  Future<SumupPluginResponse> getSavedCardReaderDetails();

  /// Returns the most recent card reader status (iOS v7+).
  Future<SumupPluginResponse> lastReaderStatus();
}
