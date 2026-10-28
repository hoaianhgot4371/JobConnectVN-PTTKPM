import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/job_model.dart';
import '../../../core/api/api_client.dart';

class JobsProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<JobModel> _jobs = [];
  List<JobModel> _recommendedJobs = [];
  List<JobModel> _myJobs = [];
  Set<int> _savedJobIds = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  int _total = 0;

  String _searchQuery = '';
  String? _filterLocation;
  String? _filterType;
  String? _filterShift;
  String? _filterSkill;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get recommendedJobs => _recommendedJobs;
  List<JobModel> get myJobs => _myJobs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get total => _total;
  String get searchQuery => _searchQuery;

  bool isSaved(int jobId) => _savedJobIds.contains(jobId);

  // ── Fetch jobs (Public) ────────────────────────────────────────────────────
  Future<void> fetchJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _jobs = [];
    }
    if (!_hasMore) return;

    if (_currentPage == 1)
      _isLoading = true;
    else
      _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get('/jobs', params: {
        'page': _currentPage,
        'limit': 20,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_filterLocation != null) 'location': _filterLocation,
        if (_filterType != null) 'type': _filterType,
        if (_filterShift != null) 'shift': _filterShift,
        if (_filterSkill != null) 'skill': _filterSkill,
      });

      final newJobs = (res.data['jobs'] as List)
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();

      _total =
          int.tryParse(res.data['total']?.toString() ?? '') ?? newJobs.length;
      _jobs = refresh ? newJobs : [..._jobs, ...newJobs];
      _hasMore = _jobs.length < _total;
      _currentPage++;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Employer: Fetch my posted jobs ─────────────────────────────────────────
  Future<void> fetchMyJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/jobs/employer/mine');
      debugPrint('[JobsProvider] My jobs response: ${res.data}');

      final list = res.data['jobs'] as List;
      _myJobs = list
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();

      debugPrint('[JobsProvider] Parsed ${_myJobs.length} jobs');
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      debugPrint('[JobsProvider] FetchMyJobs Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create job (Employer) ──────────────────────────────────────────────────
  Future<bool> createJob(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/jobs', data: data);
      final newJob = JobModel.fromJson(res.data['job'] as Map<String, dynamic>);
      _myJobs = [newJob, ..._myJobs];
      if (newJob.isActive) {
        _jobs = [newJob, ..._jobs];
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateJob(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/jobs/$id', data: data);
      final updatedJob =
          JobModel.fromJson(res.data['job'] as Map<String, dynamic>);

      _myJobs = _replaceJob(_myJobs, updatedJob);
      if (updatedJob.isActive) {
        _jobs = _replaceJob(_jobs, updatedJob);
      } else {
        _jobs.removeWhere((job) => job.id == id);
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Public methods ─────────────────────────────────────────────────────────
  Future<void> fetchRecommended() async {
    try {
      final res = await _api.get('/recommended-jobs');
      _recommendedJobs = (res.data['jobs'] as List)
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[Jobs] Recommended error: $e');
    }
  }

  Future<JobModel?> getJobDetail(int id) async {
    try {
      final res = await _api.get('/jobs/$id');
      return JobModel.fromJson(res.data['job'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<JobModel?> getJobAnalysis(int id) async {
    try {
      final res = await _api.get('/ai/jobs/$id/analysis');
      return JobModel.fromJson(res.data['job'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      return null;
    }
  }

  Future<bool> deleteJob(int id) async {
    try {
      await _api.delete('/jobs/$id');
      _myJobs.removeWhere((j) => j.id == id);
      _jobs.removeWhere((j) => j.id == id);
      _recommendedJobs.removeWhere((j) => j.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  void toggleSave(int jobId) {
    if (_savedJobIds.contains(jobId))
      _savedJobIds.remove(jobId);
    else
      _savedJobIds.add(jobId);
    notifyListeners();
  }

  String? _cleanFilter(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void setSearch(String q) {
    _searchQuery = q;
    fetchJobs(refresh: true);
  }

  void setFilters(
      {String? type, String? location, String? shift, String? skill}) {
    _filterType = _cleanFilter(type);
    _filterLocation = _cleanFilter(location);
    _filterShift = _cleanFilter(shift);
    _filterSkill = _cleanFilter(skill);
    fetchJobs(refresh: true);
  }

  void clearFilters() {
    _filterType = null;
    _filterLocation = null;
    _filterShift = null;
    _filterSkill = null;
    fetchJobs(refresh: true);
  }

  List<JobModel> _replaceJob(List<JobModel> source, JobModel updatedJob) {
    var found = false;
    final next = source.map((job) {
      if (job.id != updatedJob.id) return job;
      found = true;
      return updatedJob;
    }).toList();
    return found ? next : [updatedJob, ...next];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
