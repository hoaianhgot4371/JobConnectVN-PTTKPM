import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../features/jobs/models/job_model.dart';

// ── GradientButton ────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.colors = const [AppColors.primary, AppColors.primaryLight],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

// ── AvatarCircle ──────────────────────────────────────────────────────────────
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color bg, fg;
  final double fontSize;

    const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 40,
    this.bg = AppColors.bgPurpleLight,
    this.fg = AppColors.primary,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.sora(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ── SkillChip ─────────────────────────────────────────────────────────────────
class SkillChip extends StatelessWidget {
  final String label;
  const SkillChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6, bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.bgPurpleLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
    ),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
  );
}

// ── SectionHeader ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(children: [
      Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const Spacer(),
      if (action != null)
        GestureDetector(onTap: onAction,
          child: Text(action!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))),
    ]),
  );
}

// ── JobCard ───────────────────────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Company logo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: job.companyLogo != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.network(job.companyLogo!, fit: BoxFit.cover, width: 44, height: 44,
                        errorBuilder: (_, __, ___) => Center(child: Text(job.logoLetters,
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)))))
                  : Center(child: Text(job.logoLetters,
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(job.displayCompany, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            const SizedBox(width: 8),
            if (job.matchScore > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.bgPurpleLight, borderRadius: BorderRadius.circular(8)),
                child: Text('${job.matchScore}%', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _meta(Icons.payments_outlined, job.salary ?? 'Thoả thuận'),
            const SizedBox(width: 14),
            _meta(Icons.location_on_outlined, job.location ?? 'Remote'),
            const SizedBox(width: 14),
            _meta(Icons.access_time_outlined, job.type),
          ]),
          if (job.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(children: job.skills.take(3).map((s) => SkillChip(label: s)).toList()),
          ],
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]);
}

// ── InfoChip ──────────────────────────────────────────────────────────────────
class InfoChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const InfoChip({super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}
