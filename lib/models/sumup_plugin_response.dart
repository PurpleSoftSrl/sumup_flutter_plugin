/// Response returned from native platform
class SumupPluginResponse {
  SumupPluginResponse.fromMap(Map<dynamic, dynamic> response)
      : methodName = response['methodName'],
        status = response['status'],
        message = response['message'];

  String methodName;
  bool status;
  Map<dynamic, dynamic>? message;

  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}