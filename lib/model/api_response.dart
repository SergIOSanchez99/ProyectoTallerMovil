class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse<T>(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, message: $message, error: $error)';
  }
}
