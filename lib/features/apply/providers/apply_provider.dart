import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart' show FormData, MultipartFile;
import '../../jobs/models/job_model.dart';
import '../../../core/api/api_client.dart';

class ApplyProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<ApplicationModel> _sentApplications = [];
  List<ApplicationModel> _receivedApplications = [];
  bool _isLoading = false;
  bool _isApplying = false;
  String? _error;

  List<ApplicationModel> get sentApplications => _sentApplications;
  List<ApplicationModel> get receivedApplications => _receivedApplications;
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  String? get error => _error;

  bool hasApplied(int jobId) => _sentApplications.any((a) => a.jobId == jobId);

  // ── Apply to a job ─────────────────────────────────────────────────────────
  Future<bool> applyJob({
    required int jobId,
    String? coverLetter,
    String? cvFilePath,
  }) async {
    _isApplying = true;
    _error = null;
    notifyListeners();

    try {
      FormData formData;
      if (cvFilePath != null) {
        formData = FormData.fromMap({
          'job_id': jobId.toString(),
          if (coverLetter != null) 'cover_letter': coverLetter,
          'cv': await MultipartFile.fromFile(cvFilePath),
        });
      } else {
        formData = FormData.fromMap({
          'job_id': jobId.toString(),
          if (coverLetter != null) 'cover_letter': coverLetter,
        });
      }

      final res = await _api.postForm('/apply', formData);
      final app = ApplicationModel.fromJson(
        res.data['application'] as Map<String, dynamic>,
      );
      _sentApplications = [app, ..._sentApplications];
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  // ── Fetch sent applications (student) ─────────────────────────────────────
  Future<void> fetchSentApplications({String? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/applications', params: {
        'type': 'sent',
        if (status != null) 'status': status,
      });
      _sentApplications = (res.data['applications'] as List)
          .map((a) => ApplicationModel.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch received applications (employer) ─────────────────────────────────
  Future<void> fetchReceivedApplications({String? status, int? jobId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/applications', params: {
        'type': 'received',
        if (status != null) 'status': status,
        if (jobId != null) 'job_id': jobId,
      });
      _receivedApplications = (res.data['applications'] as List)
          .map((a) => ApplicationModel.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update application status (employer) ───────────────────────────────────
  Future<bool> updateStatus(
    int applicationId,
    String status, {
    String? note,
    DateTime? interviewAt,
    String? interviewLocation,
  }) async {
    try {
      final res = await _api.put('/applications/$applicationId/status', data: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'status_note': note.trim(),
        if (interviewAt != null) 'interview_at': interviewAt.toIso8601String(),
        if (interviewLocation != null && interviewLocation.trim().isNotEmpty)
          'interview_location': interviewLocation.trim(),
      });
      final updated = ApplicationModel.fromJson(
        res.data['application'] as Map<String, dynamic>,
      );

      // Update local list using copyWith
      _receivedApplications = _receivedApplications.map((a) {
        if (a.id == applicationId) {
          return a.copyWith(
            status: updated.status,
            statusNote: updated.statusNote,
            interviewAt: updated.interviewAt,
            interviewLocation: updated.interviewLocation,
          );
        }
        return a;
      }).toList();

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
