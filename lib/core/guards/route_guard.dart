import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';

/// Routes that DO NOT require authentication.
const _publicRoutes = {AppRoutes.initial, AppRoutes.signUpLogin};

/// Routes that are only for owners (role = 'owner').
const _ownerRoutes = {AppRoutes.ownerDashboard};

/// Wraps a screen widget and checks auth + role before showing it.
///
/// Usage: pass it as [RouteGuard.wrap] inside [onGenerateRoute].
class RouteGuard extends StatefulWidget {
  final Widget child;
  final String routeName;

  const RouteGuard({super.key, required this.child, required this.routeName});

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!mounted) return;

    // Public routes — always allowed
    if (_publicRoutes.contains(widget.routeName)) return;

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    // Not logged in → go to login
    if (session == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.signUpLogin,
        (route) => false,
      );
      return;
    }

    // Owner-only routes — check role
    if (_ownerRoutes.contains(widget.routeName)) {
      try {
        final data = await client
            .from('users')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
        if (!mounted) return;
        final role = data?['role'] as String? ?? 'customer';
        if (role != 'owner') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }
      } catch (_) {
        // On error, stay — don't kick user out
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
