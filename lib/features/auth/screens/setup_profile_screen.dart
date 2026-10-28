import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});
  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  int _step = 0; // 0 = general info, 1 = role-specific

  // General
  final _bioCtrl      = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Student
  final _universityCtrl = TextEditingController();
  final _majorCtrl      = TextEditingController();
  final _expCtrl        = TextEditingController();
  final List<String> _skills = [];
  final _skillInputCtrl = TextEditingController();

  // Employer
  final _companyNameCtrl    = TextEditingController();
  final _companyFieldCtrl   = TextEditingController();
  final _companyWebCtrl     = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _companyDescCtrl    = TextEditingController();

  @override
  void dispose() {
    for (final c in [_bioCtrl, _phoneCtrl, _locationCtrl, _universityCtrl,
      _majorCtrl, _expCtrl, _skillInputCtrl, _companyNameCtrl,
      _companyFieldCtrl, _companyWebCtrl, _companyAddressCtrl, _companyDescCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final isStudent = auth.user?.isStudent ?? true;

    final data = <String, dynamic>{
      'bio':      _bioCtrl.text.trim(),
      'phone':    _phoneCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      if (isStudent) ...{
        'university': _universityCtrl.text.trim(),
        'major':      _majorCtrl.text.trim(),
        'experience': _expCtrl.text.trim(),
        'skills':     _skills,
      } else ...{
        'company_name':    _companyNameCtrl.text.trim(),
        'company_field':   _companyFieldCtrl.text.trim(),
        'company_website': _companyWebCtrl.text.trim(),
        'company_address': _companyAddressCtrl.text.trim(),
        'company_desc':    _companyDescCtrl.text.trim(),
      },
    };

    final ok = await auth.updateProfile(data);
    if (ok && mounted) {
      // Profile done → go to main app (handled by AuthProvider state)
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Lỗi cập nhật hồ sơ'),
          backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.user?.isStudent ?? true;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Thông tin cá nhân' : 'Hoàn thiện hồ sơ',
          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0))
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: AppColors.bgCard,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              _stepDot(0, 'Cơ bản'),
              Expanded(child: Container(height: 2, color: _step >= 1 ? AppColors.primary : AppColors.border)),
              _stepDot(1, isStudent ? 'Sinh viên' : 'Công ty'),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 0 ? _buildGeneralStep() : _buildRoleStep(isStudent),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
            child: _step == 0
                ? GradientButton(label: 'Tiếp theo →', onTap: () => setState(() => _step = 1))
                : GradientButton(
                    label: auth.isLoading ? 'Đang lưu...' : 'Hoàn tất',
                    onTap: auth.isLoading ? () {} : _submit,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int idx, String label) {
    final active = _step >= idx;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: active && _step > idx
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('${idx + 1}', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: active ? AppColors.primary : AppColors.textMuted)),
      ],
    );
  }

  Widget _buildGeneralStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Giới thiệu bản thân'),
        const SizedBox(height: 6),
        TextField(
          controller: _bioCtrl, maxLines: 3,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Viết vài dòng về bản thân...'),
        ),
        const SizedBox(height: 16),
        _label('Số điện thoại'),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneCtrl, keyboardType: TextInputType.phone,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: '0901 234 567'),
        ),
        const SizedBox(height: 16),
        _label('Địa chỉ / Thành phố'),
        const SizedBox(height: 6),
        TextField(
          controller: _locationCtrl,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Hà Nội, Việt Nam'),
        ),
        const SizedBox(height: 8),
        Text('Có thể bỏ qua và hoàn thiện sau trong phần Hồ sơ.',
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildRoleStep(bool isStudent) {
    if (isStudent) return _buildStudentStep();
    return _buildEmployerStep();
  }

  Widget _buildStudentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Trường đại học / cao đẳng'),
        const SizedBox(height: 6),
        TextField(controller: _universityCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'VD: Đại học Bách Khoa Hà Nội')),
        const SizedBox(height: 16),
        _label('Ngành học'),
        const SizedBox(height: 6),
        TextField(controller: _majorCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'VD: Công nghệ thông tin')),
        const SizedBox(height: 16),
        _label('Kỹ năng (nhấn Enter để thêm)'),
        const SizedBox(height: 6),
        TextField(
          controller: _skillInputCtrl,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'VD: Flutter, Python, Figma...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: _addSkill,
            ),
          ),
          onSubmitted: (_) => _addSkill(),
        ),
        if (_skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: _skills.map((s) => Chip(
              label: Text(s, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.primary)),
              deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
              onDeleted: () => setState(() => _skills.remove(s)),
              backgroundColor: AppColors.bgPurpleLight,
              side: const BorderSide(color: AppColors.primary, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
        _label('Kinh nghiệm'),
        const SizedBox(height: 6),
        TextField(
          controller: _expCtrl, maxLines: 3,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Mô tả ngắn kinh nghiệm làm việc / thực tập...'),
        ),
      ],
    );
  }

  Widget _buildEmployerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tên công ty *'),
        const SizedBox(height: 6),
        TextField(controller: _companyNameCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'VD: Tech Corp Vietnam')),
        const SizedBox(height: 16),
        _label('Lĩnh vực hoạt động'),
        const SizedBox(height: 6),
        TextField(controller: _companyFieldCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'VD: Công nghệ phần mềm')),
        const SizedBox(height: 16),
        _label('Website công ty'),
        const SizedBox(height: 6),
        TextField(controller: _companyWebCtrl, keyboardType: TextInputType.url, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'https://company.vn')),
        const SizedBox(height: 16),
        _label('Địa chỉ công ty'),
        const SizedBox(height: 6),
        TextField(controller: _companyAddressCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: '123 Nguyễn Huệ, Q1, TP.HCM')),
        const SizedBox(height: 16),
        _label('Mô tả công ty'),
        const SizedBox(height: 6),
        TextField(controller: _companyDescCtrl, maxLines: 4, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Giới thiệu về công ty của bạn...')),
      ],
    );
  }

  void _addSkill() {
    final s = _skillInputCtrl.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() { _skills.add(s); _skillInputCtrl.clear(); });
    }
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
}
