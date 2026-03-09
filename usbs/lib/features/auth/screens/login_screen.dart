import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_colors.dart';
import 'package:usbs/config/theme/app_text_styles.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/core/services/auth_service.dart';
import 'package:usbs/features/auth/screens/auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = (String s) => AppI18n.tx(context, s);
    final isDark = AppColors.isDark(context);
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color;
    final logoBgColor = isDark
        ? const Color(0xFFE6F5F3)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.isDark(context)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111821), Color(0xFF1A2638), Color(0xFF213246)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDDE9F8), Color(0xFFEDF4FD), Color(0xFFF7FAFF)],
                ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: (AppColors.isDark(context)
                            ? const Color(0xFF6FB4E8)
                            : const Color(0xFFBED8F8))
                        .withValues(alpha: AppColors.isDark(context) ? 0.08 : 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -70,
                bottom: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: (AppColors.isDark(context)
                            ? const Color(0xFF88CBAF)
                            : const Color(0xFFBFE2D4))
                        .withValues(alpha: AppColors.isDark(context) ? 0.08 : 0.14),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0B4A45), Color(0xFF115E59)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x330F2644),
                                blurRadius: 18,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: logoBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF9FD7CC),
                                    width: 1,
                                  ),
                                ),
                                child: Image.asset('assets/logo.png'),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                t('USBS Support Portal'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t('Legal, medical, and education support for communities.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFE5ECF9),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: AppColors.elevatedSurface(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  t('Welcome'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t('Choose your access method'),
                                  style: AppTextStyles.caption.copyWith(
                                    color: subtitleColor ?? onSurface,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.g_mobiledata_rounded),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(() async {
                                            await AuthService().loginWithGoogle();
                                            if (!context.mounted) return;
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (_) => const AuthGate(),
                                              ),
                                              (route) => false,
                                            );
                                          }),
                                    label: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(t('Login with Google')),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? const Color(0xFF9BD0F7)
                                          : AppColors.secondary,
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF6FB4E8)
                                            : AppColors.secondary,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(() async {
                                            await AuthService().loginAsGuest();
                                            if (!context.mounted) return;
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (_) => const AuthGate(),
                                              ),
                                              (route) => false,
                                            );
                                          }),
                                    icon: const Icon(Icons.person_outline),
                                    label: Text(t('Continue as Guest')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(
                            alpha: AppColors.isDark(context) ? 0.24 : 0.7,
                          ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const LanguageMenuButton(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
