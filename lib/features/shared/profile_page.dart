import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/soft_card.dart';
import '../../services/app_services.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';

/// Halaman Profil / Logout sesuai PRD Section 4.1 AUTH-04 & Section 6 Layar 9:
/// - Nama, email, role (Admin / Kasir)
/// - Tombol Logout dengan dialog konfirmasi
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu login kembali untuk mengakses aplikasi POS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<CartController>().clear();
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final services = context.read<AppServices>();
    final user = auth.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profil Pengguna', style: AppTypography.heading1()),
                  const SizedBox(height: 4),
                  Text(
                    'Informasi akun dan status sistem aplikasi.',
                    style: AppTypography.bodyM(),
                  ),
                  const SizedBox(height: 20),

                  // Header Akun
                  Card(
                    elevation: 0,
                    color: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: AppTypography.heading1(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: AppTypography.heading2(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: AppTypography.caption(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RoleBadge(role: user.role),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Status Sistem
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.storage_rounded,
                          title: 'Sumber Data',
                          value: services.demoMode
                              ? 'Demo Lokal (SharedPreferences)'
                              : 'Cloud Firestore (Real-time)',
                          color: AppColors.primary,
                        ),
                        const Divider(indent: 56, endIndent: 16),
                        _InfoTile(
                          icon: Icons.payment_rounded,
                          title: 'Payment Gateway',
                          value: services.isPaymentSimulated
                              ? 'MiomiPay • Simulator Mode'
                              : 'MiomiPay • Live API',
                          color: AppColors.accent,
                        ),
                        const Divider(indent: 56, endIndent: 16),
                        _InfoTile(
                          icon: Icons.store_rounded,
                          title: 'Usaha',
                          value: AppConfig.storeName,
                          color: AppColors.success,
                        ),
                        const Divider(indent: 56, endIndent: 16),
                        _InfoTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Versi',
                          value: '${AppConfig.appName} v${AppConfig.appVersion}',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informasi Hak Akses Role
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hak Akses Role', style: AppTypography.title()),
                        const SizedBox(height: 4),
                        Text(user.role.description, style: AppTypography.bodyM()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Logout dengan konfirmasi (AUTH-04)
                  FilledButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Keluar dari Akun'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.errorSoft,
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption()),
                Text(
                  value,
                  style: AppTypography.bodyM(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
