import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiClient();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isCvUpdating = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isCvUpdating => _isCvUpdating;
  bool get isVerified => _user?.isVerified ?? false;

  // ── Boot: check stored token ───────────────────────────────────────────────
  Future<void> init() async {
    if (_status == AuthStatus.loading) return;

    final hasToken = await SecureStorage.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _fetchMe();
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _setLoading();
    try {
      final res = await _api.post('/auth/register', data: {
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
        'role': role,
      });
      final token = res.data['token'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return true;
    } on DioException catch (e) {
      _setError(ApiClient.parseError(e));
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      final res = await _api.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final token = res.data['token'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return true;
    } on DioException catch (e) {
      _setError(ApiClient.parseError(e));
      return false;
    }
  }

  // ── Google Login ───────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle({String role = 'student'}) async {
    _setLoading();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _setError('Không thể lấy ID Token từ Google');
        return false;
      }

      final res = await _api.post('/auth/google', data: {
        'idToken': idToken,
        'role': role,
      });

      final token = res.data['token'] as String;
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return true;
    } catch (e) {
      debugPrint('[Auth] Google Login Error: $e');
      _setError('Lỗi đăng nhập Google');
      return false;
    }
  }

  // ── Verify Email ───────────────────────────────────────────────────────────
  Future<bool> verifyEmail(String code) async {
    try {
      await _api.post('/auth/verify', data: {'code': code});
      if (_user != null) {
        _user = _user!.copyWith(isVerified: true);
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Resend Code ────────────────────────────────────────────────────────────
  Future<bool> resendVerificationCode() async {
    try {
      await _api.post('/auth/resend-code');
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/auth/profile', data: data);
      final userData = res.data['user'] as Map<String, dynamic>;
      final updatedUser = UserModel.fromJson(userData);
      _user = userData.containsKey('is_verified')
          ? updatedUser
          : updatedUser.copyWith(isVerified: _user?.isVerified);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadCV({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    if (filePath == null && fileBytes == null) {
      _errorMessage = 'Khong co file duoc chon';
      notifyListeners();
      return false;
    }

    _isCvUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = filePath != null
          ? await MultipartFile.fromFile(filePath, filename: fileName)
          : MultipartFile.fromBytes(fileBytes!, filename: fileName);
      final formData = FormData.fromMap({'cv': file});
      final res = await _api.postForm('/upload/cv', formData);
      final cvUrl = res.data['cv_url'] as String?;
      if (_user != null && cvUrl != null) {
        _user = _user!.copyWith(cvUrl: cvUrl);
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isCvUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCV() async {
    _isCvUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/upload/cv');
      if (_user != null) {
        _user = _user!.copyWith(clearCvUrl: true);
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isCvUpdating = false;
      notifyListeners();
    }
  }

  // ── Change password ────────────────────────────────────────────────────────
  Future<bool> changePassword({
    required String current,
    required String newPass,
  }) async {
    try {
      await _api.put('/auth/change-password', data: {
        'currentPassword': current,
        'newPassword': newPass,
      });
      return true;
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Get candidates (for employer) ──────────────────────────────────────────
  List<UserModel> _candidates = [];
  List<UserModel> get candidates => _candidates;
  bool _isFetchingCandidates = false;
  bool get isFetchingCandidates => _isFetchingCandidates;

  Future<void> fetchCandidates(
      {String? query, String? skill, String? university}) async {
    _isFetchingCandidates = true;
    notifyListeners();
    try {
      final res = await _api.get('/students', params: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (skill != null && skill.isNotEmpty) 'skill': skill,
        if (university != null && university.isNotEmpty)
          'university': university,
      });
      final list = res.data as List;
      _candidates = list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _errorMessage = ApiClient.parseError(e);
    } finally {
      _isFetchingCandidates = false;
      notifyListeners();
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();

    try {
      await SecureStorage.clearAll();
    } catch (e) {
      debugPrint('[Auth] Clear session ignored: $e');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[Auth] Google signOut ignored: $e');
    }
  }

  Future<void> refreshUser() => _fetchMe();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  Future<void> _fetchMe() async {
    if (_status == AuthStatus.loading && _user != null) return;

    _status = AuthStatus.loading;
    try {
      final res = await _api.get('/auth/me');
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      await SecureStorage.saveUserRole(_user!.role);
      await SecureStorage.saveUserId(_user!.id);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await SecureStorage.clearAll();
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.error;
        _errorMessage = ApiClient.parseError(e);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, UserModel user) async {
    await SecureStorage.saveToken(token);
    await SecureStorage.saveUserRole(user.role);
    await SecureStorage.saveUserId(user.id);
    _user = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }
}
