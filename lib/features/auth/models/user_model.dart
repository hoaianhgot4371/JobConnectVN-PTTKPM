class UserModel {
  final int id;
  final String email;
  final String name;
  final String role; // 'student' | 'employer'
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? location;

  // Student
  final String? university;
  final String? major;
  final List<String> skills;
  final String? cvUrl;
  final String? freeTime;
  final String? experience;

  // Employer
  final String? companyName;
  final String? companyField;
  final String? companyWebsite;
  final String? companyAddress;
  final String? companyLogo;
  final String? companyDesc;

  final bool isVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.location,
    this.university,
    this.major,
    this.skills = const [],
    this.cvUrl,
    this.freeTime,
    this.experience,
    this.companyName,
    this.companyField,
    this.companyWebsite,
    this.companyAddress,
    this.companyLogo,
    this.companyDesc,
    this.isVerified = false,
    this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isEmployer => role == 'employer';

  String get displayName => companyName ?? name;
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        phone: json['phone'] as String?,
        location: json['location'] as String?,
        university: json['university'] as String?,
        major: json['major'] as String?,
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        cvUrl: json['cv_url'] as String?,
        freeTime: json['free_time'] as String?,
        experience: json['experience'] as String?,
        companyName: json['company_name'] as String?,
        companyField: json['company_field'] as String?,
        companyWebsite: json['company_website'] as String?,
        companyAddress: json['company_address'] as String?,
        companyLogo: json['company_logo'] as String?,
        companyDesc: json['company_desc'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'bio': bio,
        'phone': phone,
        'location': location,
        'university': university,
        'major': major,
        'skills': skills,
        'free_time': freeTime,
        'experience': experience,
        'company_name': companyName,
        'company_field': companyField,
        'company_website': companyWebsite,
        'company_address': companyAddress,
        'company_desc': companyDesc,
      };

  UserModel copyWith({
    String? name,
    String? bio,
    String? phone,
    String? location,
    String? avatarUrl,
    String? cvUrl,
    String? university,
    String? major,
    List<String>? skills,
    String? freeTime,
    String? experience,
    String? companyName,
    String? companyField,
    String? companyWebsite,
    String? companyAddress,
    String? companyLogo,
    String? companyDesc,
    bool? isVerified,
    bool clearCvUrl = false,
  }) =>
      UserModel(
        id: id,
        email: email,
        role: role,
        createdAt: createdAt,
        name: name ?? this.name,
        bio: bio ?? this.bio,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        cvUrl: clearCvUrl ? null : cvUrl ?? this.cvUrl,
        university: university ?? this.university,
        major: major ?? this.major,
        skills: skills ?? this.skills,
        freeTime: freeTime ?? this.freeTime,
        experience: experience ?? this.experience,
        companyName: companyName ?? this.companyName,
        companyField: companyField ?? this.companyField,
        companyWebsite: companyWebsite ?? this.companyWebsite,
        companyAddress: companyAddress ?? this.companyAddress,
        companyLogo: companyLogo ?? this.companyLogo,
        companyDesc: companyDesc ?? this.companyDesc,
        isVerified: isVerified ?? this.isVerified,
      );
}
