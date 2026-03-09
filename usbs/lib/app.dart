import 'package:flutter/material.dart';
import 'package:usbs/config/theme/app_theme.dart';
import 'package:usbs/core/localization/app_language.dart';
import 'package:usbs/features/auth/screens/animated_splash_screen.dart';

// ✅ THIS import is REQUIRED
import 'config/routes/app_routes.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AppLanguageController _languageController = AppLanguageController();

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: _languageController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AnimatedSplashScreen(),
        builder: (context, child) {
          final showOverlay =
              _languageController.language != AppLanguageCode.en &&
              _languageController.hasPendingRuntimeTranslations;

          return Stack(
            children: [
              if (child != null) child,
              if (showOverlay)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x66000000),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 10),
                            Text(AppI18n.tr(context, 'translating_content')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },

        // use centralized routes
        routes: AppRoutes.routes,
      ),
    );
  }
}
