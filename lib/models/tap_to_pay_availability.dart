// ignore_for_file: public_member_api_docs

/// Result of checking Tap-to-Pay availability for the current merchant.
class TapToPayAvailabilityResult {
  TapToPayAvailabilityResult({
    required this.isAvailable,
    required this.isActivated,
    this.error,
  });

  /// Whether Tap-to-Pay is available for the current merchant/device.
  final bool isAvailable;

  /// Whether Tap-to-Pay has been activated (e.g. on iOS, activation completed).
  final bool isActivated;

  /// Error message from the native SDK, if availability check failed (e.g. init failed, attestation).
  final String? error;

  /// Deserializes a Tap-to-Pay availability result from a map (native platform bridge).
  factory TapToPayAvailabilityResult.fromMap(Map<dynamic, dynamic> map) {
    return TapToPayAvailabilityResult(
      isAvailable: map['isAvailable'] == true,
      isActivated: map['isActivated'] == true,
      error: map['error']?.toString(),
    );
  }
}
