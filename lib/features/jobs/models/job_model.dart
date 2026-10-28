import 'dart:convert';

class JobModel {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String? salary;
  final String? location;
  final String type;
  final String? shift;
  final String? category;
  final List<String> skills;
  final List<String> requirements;
  final List<String> benefits;
  final bool isActive;
  final int views;
  final int matchScore;
  final int applicantCount;
  final DateTime? expiresAt;
  final DateTime createdAt;

  final String? employerName;
  final String? companyName;
  final String? companyLogo;
  final String? companyDesc;
  final String? companyWebsite;
  final String? companyField;
  final String? recommendationReason;
  final String? companyFit;
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const JobModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.salary,
    this.location,
    this.type = 'Part-time',
    this.shift,
    this.category,
    this.skills = const [],
    this.requirements = const [],
    this.benefits = const [],
    this.isActive = true,
    this.views = 0,
    this.matchScore = 0,
    this.applicantCount = 0,
    this.expiresAt,
    required this.createdAt,
    this.employerName,
    this.companyName,
    this.companyLogo,
    this.companyDesc,
    this.companyWebsite,
    this.companyField,
    this.recommendationReason,
    this.companyFit,
    this.matchedSkills = const [],
    this.missingSkills = const [],
  });

  String get displayCompany => companyName ?? employerName ?? '—';

  String get logoLetters {
    final name = displayCompany;
    final words =
        name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    final compactName = name.trim();
    return compactName.length >= 2
        ? compactName.substring(0, 2).toUpperCase()
        : (compactName.isEmpty ? 'JC' : compactName.toUpperCase());
  }

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        title: (json['title'] ?? 'Không tiêu đề') as String,
        description: (json['description'] ?? '') as String,
        salary: json['salary'] as String?,
        location: json['location'] as String?,
        type: (json['type'] ?? 'Part-time') as String,
        shift: json['shift'] as String?,
        category: json['category'] as String?,
        skills: _parseStringList(json['skills']),
        requirements: _parseStringList(json['requirements']),
        benefits: _parseStringList(json['benefits']),
        isActive: (json['is_active'] ?? true) as bool,
        views: _parseInt(json['views']),
        matchScore: _parseInt(json['match_score']),
        applicantCount:
            int.tryParse(json['applicant_count']?.toString() ?? '0') ?? 0,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        employerName: json['employer_name'] as String?,
        companyName: json['company_name'] as String?,
        companyLogo: json['company_logo'] as String?,
        companyDesc: json['company_desc'] as String?,
        companyWebsite: json['company_website'] as String?,
        companyField: json['company_field'] as String?,
        recommendationReason: json['recommendation_reason'] as String?,
        companyFit: json['company_fit'] as String?,
        matchedSkills: _parseStringList(json['matched_skills']),
        missingSkills: _parseStringList(json['missing_skills']),
      );

  static List<String> _parseStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) {
      if (val.startsWith('[') && val.endsWith(']')) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return val
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'salary': salary,
        'location': location,
        'type': type,
        'shift': shift,
        'category': category,
        'skills': skills,
        'requirements': requirements,
        'benefits': benefits,
        'is_active': isActive,
        'views': views,
        'match_score': matchScore,
        'applicant_count': applicantCount,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class ApplicationModel {
  final int id;
  final int jobId;
  final int userId;
  final String? cvUrl;
  final String? coverLetter;
  final String status;
  final String? statusNote;
  final DateTime? interviewAt;
  final String? interviewLocation;
  final int matchScore;
  final DateTime createdAt;

  final String? jobTitle;
  final String? salary;
  final String? location;
  final String? type;
  final String? employerName;
  final String? companyName;

  final String? name;
  final String? email;
  final String? avatarUrl;
  final List<String>? skills;
  final String? university;
  final String? major;
  final String? applicantLocation;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    this.cvUrl,
    this.coverLetter,
    required this.status,
    this.statusNote,
    this.interviewAt,
    this.interviewLocation,
    required this.matchScore,
    required this.createdAt,
    this.jobTitle,
    this.salary,
    this.location,
    this.type,
    this.employerName,
    this.companyName,
    this.name,
    this.email,
    this.avatarUrl,
    this.skills,
    this.university,
    this.major,
    this.applicantLocation,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      ApplicationModel(
        id: JobModel._parseInt(json['id']),
        jobId: JobModel._parseInt(json['job_id']),
        userId: JobModel._parseInt(json['user_id']),
        cvUrl: json['cv_url'] as String?,
        coverLetter: json['cover_letter'] as String?,
        status: (json['status'] ?? 'pending') as String,
        statusNote: json['status_note'] as String?,
        interviewAt: json['interview_at'] != null
            ? DateTime.tryParse(json['interview_at'].toString())
            : null,
        interviewLocation: json['interview_location'] as String?,
        matchScore: JobModel._parseInt(json['match_score']),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        jobTitle: json['title'] ?? json['job_title'] as String?,
        salary: json['salary'] as String?,
        location: json['location'] as String?,
        type: json['type'] as String?,
        employerName: json['employer_name'] as String?,
        companyName: json['company_name'] as String?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        skills: json['skills'] != null
            ? JobModel._parseStringList(json['skills'])
            : null,
        university: json['university'] as String?,
        major: json['major'] as String?,
        applicantLocation: json['applicant_location'] as String?,
      );

  ApplicationModel copyWith({
    String? status,
    String? statusNote,
    DateTime? interviewAt,
    String? interviewLocation,
  }) {
    return ApplicationModel(
      id: id,
      jobId: jobId,
      userId: userId,
      createdAt: createdAt,
      matchScore: matchScore,
      cvUrl: cvUrl,
      coverLetter: coverLetter,
      statusNote: statusNote ?? this.statusNote,
      interviewAt: interviewAt ?? this.interviewAt,
      interviewLocation: interviewLocation ?? this.interviewLocation,
      jobTitle: jobTitle,
      salary: salary,
      location: location,
      type: type,
      employerName: employerName,
      companyName: companyName,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      skills: skills,
      university: university,
      major: major,
      applicantLocation: applicantLocation,
      status: status ?? this.status,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'viewed':
        return 'Đã xem';
      case 'interview':
        return 'Phỏng vấn';
      case 'accepted':
        return 'Đã nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }
}
