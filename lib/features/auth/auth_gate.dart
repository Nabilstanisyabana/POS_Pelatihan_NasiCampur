import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../admin/admin_shell.dart';
import '../cashier/cashier_shell.dart';
import '../shared/splash_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final Widget child;
        if (auth.initializing) {
          child = const SplashScreen(key: ValueKey('splash'));
        } else if (auth.user == null) {
          child = const LoginScreen(key: ValueKey('login'));
        } else if (auth.user!.isAdmin) {
          child = const AdminShell(key: ValueKey('admin'));
        } else {
          child = const CashierShell(key: ValueKey('cashier'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}
