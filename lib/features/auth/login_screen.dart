import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/app_user.dart';
import '../../state/auth_controller.dart';
import 'register_screen.dart';

/// Halaman Login sesuai PRD Section 4.1, 18, dan 19
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthController>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _quickDemo(UserRole role) async {
    _emailController.text = role == UserRole.admin
        ? 'admin@nusapos.id'
        : 'kasir@nusapos.id';
    _passwordController.text = role == UserRole.admin ? 'admin123' : 'kasir123';
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // [Logo + nama aplikasi]
                        const Center(child: AppLogo(size: 48)),
                        const SizedBox(height: 20),

                        // Selamat datang kembali
                        Text(
                          'Selamat datang kembali',
                          textAlign: TextAlign.center,
                          style: AppTypography.heading1(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masuk ke akun POS untuk melanjutkan.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyM(),
                        ),
                        const SizedBox(height: 24),

                        // Error Banner (Microcopy 19)
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: AppTypography.caption(
                                      color: AppColors.error,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Input Email (Label di atas field per PRD Section 16)
                        Text(
                          'Email',
                          style: AppTypography.label().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Email wajib diisi';
                            if (!email.contains('@')) {
                              return 'Format email tidak valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Input Password (Label di atas field per PRD Section 16)
                        Text(
                          'Password',
                          style: AppTypography.label().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Password wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tombol Masuk (Lebar penuh, tinggi 52 dp, latar primary)
                        PrimaryButton(
                          text: 'Masuk',
                          loading: auth.busy,
                          onPressed: auth.busy ? null : _submit,
                        ),

                        // Quick demo buttons
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'Coba Cepat Demo',
                                style: AppTypography.caption(),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: auth.busy
                                    ? null
                                    : () => _quickDemo(UserRole.admin),
                                icon: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 16,
                                ),
                                label: const Text('Admin'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: auth.busy
                                    ? null
                                    : () => _quickDemo(UserRole.kasir),
                                icon: const Icon(
                                  Icons.point_of_sale_rounded,
                                  size: 16,
                                ),
                                label: const Text('Kasir'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun? ',
                              style: AppTypography.bodyM(),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Daftar di sini'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
