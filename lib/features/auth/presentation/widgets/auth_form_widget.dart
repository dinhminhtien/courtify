import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AuthFormWidget extends StatefulWidget {
  final bool isLogin;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;

  const AuthFormWidget({
    super.key,
    required this.isLogin,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.fullNameController,
    required this.phoneController,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(widget.isLogin),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isLogin) ...[
              _buildLabel('Họ và tên'),
              const SizedBox(height: 6),
              TextFormField(
                controller: widget.fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  'Nhập họ và tên đầy đủ',
                  Icons.person_outline_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (v.trim().length < 3) return 'Họ và tên quá ngắn';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildLabel('Số điện thoại'),
              const SizedBox(height: 6),
              TextFormField(
                controller: widget.phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  '0912 345 678',
                  Icons.phone_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^(0|\+84)[0-9]{9}$').hasMatch(v.trim())) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            _buildLabel('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                'example@email.com',
                Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('Mật khẩu'),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              decoration:
                  _inputDecoration(
                    'Nhập mật khẩu',
                    Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.muted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                return null;
              },
            ),
            if (!widget.isLogin) ...[
              const SizedBox(height: 14),
              _buildLabel('Xác nhận mật khẩu'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration:
                    _inputDecoration(
                      'Nhập lại mật khẩu',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.muted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (v != widget.passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.muted,
      ),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.muted),
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
