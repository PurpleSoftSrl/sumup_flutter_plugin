/// Response returned from the native platform via the method channel.
class SumupPluginResponse {
  /// Creates a response from the native channel map.
  SumupPluginResponse.fromMap(Map<dynamic, dynamic> response)
      : methodName = response['methodName'] as String,
        status = response['status'] as bool,
        message = response['message'] as Map<dynamic, dynamic>?;

  /// The method channel method name this response refers to.
  String methodName;

  /// Whether the native operation completed successfully.
  bool status;

  /// Optional response data returned by the native layer.
  Map<dynamic, dynamic>? message;

  @override
  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}
