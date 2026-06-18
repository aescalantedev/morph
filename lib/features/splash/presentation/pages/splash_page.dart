import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../shared/presentation/widgets/app_logo.dart';

/// A premium animated startup loading screen that serves as a splash screen,
/// fully integrated with GoRouter.
class SplashPage extends StatefulWidget {
  /// Creates the [SplashPage] widget.
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _loaderFadeAnimation;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();

    // 1.5 seconds animation duration for entry animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Cascading scale animation for the logo
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Fade in for the logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Fade in for the title "Morph"
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Fade in for the loader and subtitle
    _loaderFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Set a minimum timer of 1.8 seconds to display the entry animations fully
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _timerDone = true;
        });
        _checkAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAndNavigate() {
    final settingsState = context.read<SettingsBloc>().state;
    if (_timerDone && settingsState.isLoaded) {
      context.go(initialLocationOverride);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) => !previous.isLoaded && current.isLoaded,
      listener: (context, state) {
        _checkAndNavigate();
      },
      builder: (context, settingsState) {
        // Determine theme brightness dynamically based on current state or system settings
        final isSystemDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        final isDark = settingsState.themeMode == ThemeMode.dark ||
            (settingsState.themeMode == ThemeMode.system && isSystemDark);

        final themeColor = settingsState.themeColor;
        final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F6FA);
        final textColor = isDark ? Colors.white : const Color(0xFF1E1E24);
        final subtitleColor = isDark ? const Color(0xFF9E9EAE) : const Color(0xFF6B6B78);

        return Scaffold(
          backgroundColor: bgColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                 AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AppLogo(
                            size: 90,
                            color: themeColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Animated App Name
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Text(
                        'Morph',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          fontFamily: 'Inter',
                          letterSpacing: -1.5,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Animated Subtitle / Loading Indicator
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loaderFadeAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            settingsState.languageCode == 'es'
                                ? 'Cargando herramientas...'
                                : 'Loading tools...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                              fontFamily: 'Inter',
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
