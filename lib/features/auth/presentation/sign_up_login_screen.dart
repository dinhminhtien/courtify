import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './providers/auth_provider.dart';
import './widgets/auth_form_widget.dart';
import './widgets/auth_header_widget.dart';
import './widgets/demo_credentials_widget.dart';
import './widgets/social_login_widget.dart';

class SignUpLoginScreen extends ConsumerStatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  ConsumerState<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends ConsumerState<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;

  late AnimationController _bgController;
  late Animation<Color?> _bgColorAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  static const String _demoEmail = 'nguyenvannam@courtify.vn';
  static const String _demoPassword = 'Courtify@2026';
  static const String _ownerEmail = 'owner@courtify.vn';
  static const String _ownerPassword = 'Owner@2026';

  StreamSubscription<supabase.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bgColorAnimation =
        ColorTween(
          begin: const Color(0xFFF1F8E9),
          end: const Color(0xFFE8F5E9),
        ).animate(
          CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic),
        );

    // Listen for OAuth callback (page reload after Google redirect)
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        if (data.event == supabase.AuthChangeEvent.signedIn && data.session != null) {
          await ref.read(authProvider.notifier).refreshProfile();
          if (!mounted) return;
          final user = ref.read(currentUserProvider);
          if (user?.isOwner == true) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.ownerDashboard,
              (route) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          }
        }
      },
    );

    // Check if already logged in
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingSession(),
    );
  }

  Future<void> _checkExistingSession() async {
    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier.isLoggedIn) {
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user?.isOwner == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.ownerDashboard,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    if (_isLogin) {
      _bgController.reverse();
    } else {
      _bgController.forward();
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isLogin) {
      success = await ref
          .read(authProvider.notifier)
          .signIn(email: email, password: password);
    } else {
      success = await ref
          .read(authProvider.notifier)
          .signUp(
            email: email,
            password: password,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
    }

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      _showError(_mapAuthError(authState.error!));
      return;
    }

    if (success) {
      final user = ref.read(currentUserProvider);
      if (user?.isOwner == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.ownerDashboard,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    } else if (message.contains('Email not confirmed')) {
      return 'Email chưa được xác nhận.';
    } else if (message.contains('User already registered')) {
      return 'Email này đã được đăng ký.';
    } else if (message.contains('Password should be')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      _showError('Đăng nhập Google thất bại. Vui lòng thử lại.');
      return;
    }

    if (success) {
      final user = ref.read(currentUserProvider);
      if (user?.isOwner == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.ownerDashboard,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isLoading = ref.watch(isAuthLoadingProvider);

    return AnimatedBuilder(
      animation: _bgColorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bgColorAnimation.value,
          body: SafeArea(
            child: isTablet
                ? _buildTabletLayout(isLoading)
                : _buildPhoneLayout(isLoading),
          ),
        );
      },
    );
  }

  Widget _buildPhoneLayout(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          AuthHeaderWidget(isLogin: _isLogin),
          const SizedBox(height: 32),
          _buildFormCard(isLoading),
          const SizedBox(height: 16),
          DemoCredentialsWidget(
            demoEmail: _demoEmail,
            demoPassword: _demoPassword,
            ownerEmail: _ownerEmail,
            ownerPassword: _ownerPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isLoading) {
    return Center(
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            children: [
              AuthHeaderWidget(isLogin: _isLogin),
              const SizedBox(height: 32),
              _buildFormCard(isLoading),
              const SizedBox(height: 16),
              DemoCredentialsWidget(
                demoEmail: _demoEmail,
                demoPassword: _demoPassword,
                ownerEmail: _ownerEmail,
                ownerPassword: _ownerPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormWidget(
            formKey: _formKey,
            isLogin: _isLogin,
            emailController: _emailController,
            passwordController: _passwordController,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SocialLoginWidget(onGooglePressed: _handleGoogleLogin),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.muted,
                ),
              ),
              GestureDetector(
                onTap: _toggleMode,
                child: Text(
                  _isLogin ? 'Đăng ký' : 'Đăng nhập',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
