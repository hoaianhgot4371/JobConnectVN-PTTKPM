import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();

  Future<void> _handleVerify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã xác thực gồm 6 chữ số')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(code);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác thực tài khoản thành công!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Mã xác thực không đúng')),
      );
    }
  }

  Future<void> _handleResend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerificationCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã gửi lại mã xác thực!' : (auth.errorMessage ?? 'Không thể gửi lại mã')),
          backgroundColor: ok ? AppColors.green : AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xác thực tài khoản', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Nhập mã xác thực',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Mã xác thực đã được gửi tới email của bạn. Vui lòng kiểm tra hộp thư đến hoặc thư rác.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                filled: true,
                fillColor: AppColors.bgPurpleLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => GradientButton(
                label: auth.isLoading ? 'Đang kiểm tra...' : 'Xác nhận',
                onTap: auth.isLoading ? () {} : _handleVerify,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _handleResend,
              child: Text(
                'Chưa nhận được mã? Gửi lại',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
