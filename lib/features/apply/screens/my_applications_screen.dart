import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/apply_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../jobs/models/job_model.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../jobs/screens/student_detail_screen.dart';
import '../../auth/models/user_model.dart';

class MyApplicationsScreen extends StatefulWidget {
  final int? jobId;
  const MyApplicationsScreen({super.key, this.jobId});
  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _statuses = [
    'Tất cả',
    'pending',
    'viewed',
    'interview',
    'accepted',
    'rejected'
  ];
  final _statusLabels = [
    'Tất cả',
    'Đang chờ',
    'Đã xem',
    'Phỏng vấn',
    'Được nhận',
    'Từ chối'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.role == 'employer') {
        context
            .read<ApplyProvider>()
            .fetchReceivedApplications(jobId: widget.jobId);
      } else {
        context.read<ApplyProvider>().fetchSentApplications();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isEmployer = user?.role == 'employer';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
            isEmployer
                ? (widget.jobId != null
                    ? 'Ứng viên cho công việc'
                    : 'Ứng viên đã ứng tuyển')
                : 'Đơn ứng tuyển của tôi',
            style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgCard,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle:
              GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _statusLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Consumer<ApplyProvider>(builder: (ctx, apply, _) {
        if (apply.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final applications =
            isEmployer ? apply.receivedApplications : apply.sentApplications;

        return TabBarView(
          controller: _tab,
          children: _statuses.map((status) {
            final list = status == 'Tất cả'
                ? applications
                : applications.where((a) => a.status == status).toList();

            if (list.isEmpty) return _emptyState();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => isEmployer
                  ? apply.fetchReceivedApplications(jobId: widget.jobId)
                  : apply.fetchSentApplications(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: list.length,
                itemBuilder: (ctx, i) => isEmployer
                    ? _ReceivedApplicationCard(app: list[i])
                    : _SentApplicationCard(app: list[i]),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _emptyState() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_outlined, size: 52, color: AppColors.border),
        const SizedBox(height: 12),
        Text('Không có dữ liệu',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary)),
      ]));
}

class _SentApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  const _SentApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(app.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(app.jobTitle ?? 'Công việc',
                  style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary))),
          _StatusBadge(label: app.statusLabel, config: statusConfig),
        ]),
        Text(app.companyName ?? app.employerName ?? 'Công ty',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(_relativeTime(app.createdAt),
              style:
                  GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          _MatchScoreBadge(matchScore: app.matchScore),
        ]),
        const SizedBox(height: 12),
        _ApplicationSteps(status: app.status),
        if (_hasApplicationDetails(app)) ...[
          const SizedBox(height: 10),
          _ApplicationDetails(app: app),
        ],
      ]),
    );
  }
}

class _ReceivedApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  const _ReceivedApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(app.status);
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StudentDetailScreen(
                      student: UserModel(
                        id: app.userId,
                        email: app.email ?? '',
                        role: 'student',
                        name: app.name ?? 'Ứng viên',
                        avatarUrl: app.avatarUrl,
                        skills: app.skills ?? <String>[],
                        university: app.university,
                        major: app.major,
                        location: app.applicantLocation,
                      ),
                      application: app,
                    )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AvatarCircle(
              initials: (app.name ?? 'U').substring(0, 1).toUpperCase(),
              size: 40,
              bg: AppColors.bgPurpleLight,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name ?? 'Ẩn danh',
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('Ứng tuyển: ${app.jobTitle}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            _StatusBadge(label: app.statusLabel, config: statusConfig),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.school_outlined,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
                child: Text(app.university ?? 'Chưa cập nhật trường',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            _MatchScoreBadge(matchScore: app.matchScore),
          ]),
          if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '\"${app.coverLetter}\"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
          if (_hasApplicationDetails(app)) ...[
            const SizedBox(height: 8),
            _ApplicationDetails(app: app),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_relativeTime(app.createdAt),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textHint)),
              Flexible(
                child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (app.cvUrl != null && app.cvUrl!.isNotEmpty)
                        _ActionButton(
                            label: 'CV',
                            color: AppColors.primary,
                            onTap: () => _openCv(app.cvUrl!)),
                      if (app.status != 'accepted' && app.status != 'rejected')
                        _ActionButton(
                            label: 'Phỏng vấn',
                            color: AppColors.primary,
                            onTap: () => _showInterviewSheet(context, app)),
                      _ActionButton(
                          label: 'Từ chối',
                          color: AppColors.red,
                          onTap: () =>
                              _showDecisionSheet(context, app, 'rejected')),
                      _ActionButton(
                          label: 'Nhận',
                          color: AppColors.green,
                          onTap: () =>
                              _showDecisionSheet(context, app, 'accepted')),
                    ]),
              )
            ],
          )
        ]),
      ),
    );
  }

  Future<void> _openCv(String cvUrl) async {
    final uri = Uri.parse(ApiClient.resolveFileUrl(cvUrl));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

bool _hasApplicationDetails(ApplicationModel app) {
  return app.statusNote?.isNotEmpty == true ||
      app.interviewAt != null ||
      app.interviewLocation?.isNotEmpty == true;
}

class _ApplicationSteps extends StatelessWidget {
  final String status;
  const _ApplicationSteps({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';
    final steps = [
      ('pending', 'Nộp đơn'),
      ('viewed', 'Đã xem'),
      ('interview', 'Phỏng vấn'),
      (
        isRejected ? 'rejected' : 'accepted',
        isRejected ? 'Từ chối' : 'Kết quả'
      ),
    ];
    final currentIndex = switch (status) {
      'pending' => 0,
      'viewed' => 1,
      'interview' => 2,
      'accepted' || 'rejected' => 3,
      _ => 0,
    };

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentIndex;
        final color = isDone
            ? (isRejected && index == steps.length - 1
                ? AppColors.red
                : AppColors.primary)
            : AppColors.border;
        return Expanded(
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : color.withOpacity(0.35))),
                Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 17, color: color),
                Expanded(
                    child: Container(
                        height: 2,
                        color: index == steps.length - 1
                            ? Colors.transparent
                            : color.withOpacity(0.35))),
              ]),
              const SizedBox(height: 4),
              Text(steps[index].$2,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: isDone ? color : AppColors.textHint),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      }),
    );
  }
}

class _ApplicationDetails extends StatelessWidget {
  final ApplicationModel app;
  const _ApplicationDetails({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgPurpleLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (app.interviewAt != null)
          _DetailLine(
              icon: Icons.event_available,
              text: 'Phỏng vấn: ${_formatDateTime(app.interviewAt!)}'),
        if (app.interviewLocation?.isNotEmpty == true)
          _DetailLine(
              icon: Icons.location_on_outlined, text: app.interviewLocation!),
        if (app.statusNote?.isNotEmpty == true)
          _DetailLine(icon: Icons.notes_outlined, text: app.statusNote!),
      ]),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary))),
      ]),
    );
  }
}

Future<void> _showDecisionSheet(
    BuildContext context, ApplicationModel app, String status) async {
  final noteCtrl = TextEditingController();
  final isAccepted = status == 'accepted';
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAccepted ? 'Nhận ứng viên' : 'Từ chối ứng viên',
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isAccepted
                      ? 'Ghi chú gửi ứng viên (tuỳ chọn)'
                      : 'Lý do từ chối (tuỳ chọn)',
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: isAccepted ? 'Xác nhận nhận' : 'Xác nhận từ chối',
                onTap: () async {
                  final provider = context.read<ApplyProvider>();
                  Navigator.pop(context);
                  await provider.updateStatus(app.id, status,
                      note: noteCtrl.text);
                },
              ),
            ]),
      ),
    ),
  );
  noteCtrl.dispose();
}

Future<void> _showInterviewSheet(
    BuildContext context, ApplicationModel app) async {
  DateTime? interviewAt = app.interviewAt;
  final locationCtrl = TextEditingController(text: app.interviewLocation ?? '');
  final noteCtrl = TextEditingController(text: app.statusNote ?? '');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hẹn phỏng vấn',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: sheetContext,
                      initialDate: interviewAt ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 120)),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(
                      context: sheetContext,
                      initialTime: TimeOfDay.fromDateTime(interviewAt ??
                          DateTime.now().add(const Duration(hours: 1))),
                    );
                    if (time == null) return;
                    setSheetState(() {
                      interviewAt = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    });
                  },
                  icon: const Icon(Icons.event_available),
                  label: Text(interviewAt == null
                      ? 'Chọn thời gian phỏng vấn'
                      : _formatDateTime(interviewAt!)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Địa điểm hoặc link phỏng vấn'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Ghi chú cho ứng viên'),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Gửi lịch phỏng vấn',
                  onTap: () async {
                    final provider = context.read<ApplyProvider>();
                    Navigator.pop(context);
                    await provider.updateStatus(
                      app.id,
                      'interview',
                      note: noteCtrl.text,
                      interviewAt: interviewAt,
                      interviewLocation: locationCtrl.text,
                    );
                  },
                ),
              ]),
        ),
      ),
    ),
  );

  locationCtrl.dispose();
  noteCtrl.dispose();
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Map<String, Color> config;
  const _StatusBadge({required this.label, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: config['bg'], borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: config['fg'])),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  final int matchScore;
  const _MatchScoreBadge({required this.matchScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.bgPurpleLight,
          borderRadius: BorderRadius.circular(6)),
      child: Text('$matchScore% phù hợp',
          style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

Map<String, Color> _getStatusConfig(String status) {
  switch (status) {
    case 'pending':
      return {'bg': const Color(0xFFFFF7E0), 'fg': const Color(0xFFB45309)};
    case 'viewed':
      return {'bg': const Color(0xFFE8F4FF), 'fg': const Color(0xFF2563EB)};
    case 'interview':
      return {'bg': const Color(0xFFF0EDFF), 'fg': AppColors.primary};
    case 'accepted':
      return {'bg': const Color(0xFFEDFAF4), 'fg': AppColors.green};
    case 'rejected':
      return {'bg': const Color(0xFFFEF0F0), 'fg': AppColors.red};
    default:
      return {'bg': AppColors.bgPage, 'fg': AppColors.textMuted};
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays} ngày trước';
  if (diff.inHours > 0) return '${diff.inHours} giờ trước';
  return '${diff.inMinutes} phút trước';
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '${local.hour}:$minute $day/$month/${local.year}';
}
