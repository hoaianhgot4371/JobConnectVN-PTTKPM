import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  // THAY ĐỔI TẠI ĐÂY: Nếu dùng máy thật, hãy dùng IP máy tính của bạn (ví dụ 192.168.1.5)
  static String get _baseUrl {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:3002/api';
    }
    return 'http://10.0.2.2:3002/api';
  }

  static String resolveFileUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final apiUri = Uri.parse(_baseUrl);
    return apiUri.replace(path: url).toString();
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 45), // Tăng lên 45s để test
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[API-Request] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API-Response] Status: ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint('[API-Error] Type: ${e.type}');
          debugPrint('[API-Error] Message: ${e.message}');
          debugPrint('[API-Error] Endpoint: ${e.requestOptions.uri}');

          if (e.response?.statusCode == 401) {
            await SecureStorage.clearToken();
          }
          handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
  Future<Response> postForm(String path, FormData formData) => _dio.post(path,
      data: formData, options: Options(contentType: 'multipart/form-data'));

  static String parseError(DioException e) {
    if (e.response?.data is Map) {
      return e.response?.data['error'] ?? 'Lỗi không xác định';
    }
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Không thể kết nối tới Server (Timeout).';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Server phản hồi quá lâu.';
    if (e.type == DioExceptionType.connectionError)
      return 'Lỗi kết nối mạng hoặc Server chưa bật.';
    return 'Lỗi: ${e.message}';
  }
}
