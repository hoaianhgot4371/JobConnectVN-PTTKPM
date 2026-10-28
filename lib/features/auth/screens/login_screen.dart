import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'setup_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscure = true;
  bool _obscureReg = true;

  // Login
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  // Register
  final _nameCtrl    = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl  = TextEditingController();
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    _nameCtrl.dispose(); _regEmailCtrl.dispose(); _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('Vui lòng nhập email và mật khẩu');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!ok && mounted) _showError(auth.errorMessage ?? 'Đăng nhập thất bại');
  }

  Future<void> _handleGoogleAuth() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle(
      role: _isLogin ? 'student' : _selectedRole,
    );
    if (ok && mounted) {
      if (!_isLogin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
        );
      }
    } else if (!ok && mounted) {
      _showError(auth.errorMessage ?? 'Lỗi xác thực Google');
    }
  }

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _regEmailCtrl.text.trim().isEmpty ||
        _regPassCtrl.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email:    _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text,
      name:     _nameCtrl.text.trim(),
      role:     _selectedRole,
    );
    if (ok && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
      );
    } else if (!ok && mounted) {
      _showError(auth.errorMessage ?? 'Đăng ký thất bại');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: SingleChildScrollView(
        child: Column(
          children: [_buildHero(), _buildBody()],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B30D4), Color(0xFF7C5DFA), Color(0xFFFF7B4F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text('JobConnect VN', style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Nền tảng việc làm thông minh cho sinh viên', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.78))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabToggle(),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (ctx, auth, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLogin
                    ? _buildLoginForm(auth)
                    : _buildRegisterForm(auth),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildGoogleButton(),
          const SizedBox(height: 24),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Bằng cách tiếp tục, bạn đồng ý với ',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {},
                      child: Text('Điều khoản sử dụng', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF5F4F8), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [_tabBtn('Đăng nhập', true), _tabBtn('Đăng ký', false)]),
    );
  }

  Widget _tabBtn(String label, bool isLoginTab) {
    final selected = _isLogin == isLoginTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isLogin = isLoginTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 1))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Email'),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'you@example.com'),
        ),
        const SizedBox(height: 14),
        _label('Mật khẩu'),
        const SizedBox(height: 6),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Quên mật khẩu?', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 4),
        GradientButton(
          label: auth.isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
          onTap: auth.isLoading ? () {} : _handleLogin,
        ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Họ và tên'),
        const SizedBox(height: 6),
        TextField(controller: _nameCtrl, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Nguyễn Minh Tú')),
        const SizedBox(height: 14),
        _label('Email'),
        const SizedBox(height: 6),
        TextField(controller: _regEmailCtrl, keyboardType: TextInputType.emailAddress, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'you@example.com')),
        const SizedBox(height: 14),
        _label('Mật khẩu'),
        const SizedBox(height: 6),
        TextField(
          controller: _regPassCtrl,
          obscureText: _obscureReg,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tối thiểu 6 ký tự',
            suffixIcon: IconButton(
              icon: Icon(_obscureReg ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() => _obscureReg = !_obscureReg),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label('Bạn là'),
        const SizedBox(height: 8),
        Row(
          children: [
            _roleChip('Sinh viên', 'student', Icons.school_outlined),
            const SizedBox(width: 12),
            _roleChip('Nhà tuyển dụng', 'employer', Icons.business_outlined),
          ],
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: auth.isLoading ? 'Đang tạo tài khoản...' : 'Tạo tài khoản',
          onTap: auth.isLoading ? () {} : _handleRegister,
        ),
      ],
    );
  }

  Widget _roleChip(String label, String value, IconData icon) {
    final selected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgPurpleLight : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary));

  Widget _buildDivider() => Row(children: [
    const Expanded(child: Divider()),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted))),
    const Expanded(child: Divider()),
  ]);

  Widget _buildGoogleButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => OutlinedButton(
        onPressed: auth.isLoading ? null : _handleGoogleAuth,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (auth.isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              const Icon(Icons.g_mobiledata_rounded, size: 28, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                _isLogin ? 'Tiếp tục với Google' : 'Đăng ký bằng Google',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
