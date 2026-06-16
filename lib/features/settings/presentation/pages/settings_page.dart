import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
import '../../../converter/presentation/bloc/converter_event.dart';
import '../../../converter/presentation/bloc/converter_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

/// The page containing user preferences (appearance, language, notification controls)
/// and technical details about the conversion engine.
///
/// Implements responsive layouts for desktop (split columns) and mobile (stacked).
class SettingsPage extends StatelessWidget {
  /// Creates a [SettingsPage] widget.
  const SettingsPage({super.key});

  /// Opens the native directory chooser to select default output folders.
  Future<void> _selectDirectory(BuildContext context) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && context.mounted) {
        context.read<ConverterBloc>().add(ChangeSavePathEvent(selectedDirectory));
      }
    } catch (_) {}
  }

  /// Builds a card containing global preference toggles (theme, language, notification switches).
  Widget _buildPreferencesCard(
    BuildContext context,
    SettingsState settingsState,
    ConverterState converterState,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, size: 22, color: AppTheme.primary(context)),
              const SizedBox(width: 10),
              Text(
                localizations.globalSettings,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // --- THEME SELECTOR ---
          Text(
            localizations.theme,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSegmentedButton(
                context: context,
                label: localizations.themeLight,
                icon: Icons.light_mode_outlined,
                isSelected: settingsState.themeMode == ThemeMode.light,
                onTap: () => context.read<SettingsBloc>().add(const UpdateThemeModeEvent(ThemeMode.light)),
              ),
              const SizedBox(width: 8),
              _buildSegmentedButton(
                context: context,
                label: localizations.themeDark,
                icon: Icons.dark_mode_outlined,
                isSelected: settingsState.themeMode == ThemeMode.dark,
                onTap: () => context.read<SettingsBloc>().add(const UpdateThemeModeEvent(ThemeMode.dark)),
              ),
              const SizedBox(width: 8),
              _buildSegmentedButton(
                context: context,
                label: localizations.themeSystem,
                icon: Icons.settings_brightness_outlined,
                isSelected: settingsState.themeMode == ThemeMode.system,
                onTap: () => context.read<SettingsBloc>().add(const UpdateThemeModeEvent(ThemeMode.system)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // --- THEME COLOR SELECTOR ---
          Text(
            localizations.themeColor,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildColorOption(context, const Color(0xFF24389C), settingsState.themeColor, 'Indigo'),
              _buildColorOption(context, const Color(0xFF007A87), settingsState.themeColor, 'Teal'),
              _buildColorOption(context, const Color(0xFF2E7D32), settingsState.themeColor, 'Forest Green'),
              _buildColorOption(context, const Color(0xFFD97706), settingsState.themeColor, 'Orange'),
              _buildColorOption(context, const Color(0xFF6D28D9), settingsState.themeColor, 'Purple'),
              _buildColorOption(context, const Color(0xFFE11D48), settingsState.themeColor, 'Rose'),
            ],
          ),
          const SizedBox(height: 28),

          // --- LANGUAGE SELECTOR ---
          Text(
            localizations.language,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSegmentedButton(
                context: context,
                label: 'Español',
                icon: Icons.translate_outlined,
                isSelected: settingsState.languageCode == 'es',
                onTap: () => context.read<SettingsBloc>().add(const UpdateLanguageEvent('es')),
              ),
              const SizedBox(width: 8),
              _buildSegmentedButton(
                context: context,
                label: 'English',
                icon: Icons.translate_outlined,
                isSelected: settingsState.languageCode == 'en',
                onTap: () => context.read<SettingsBloc>().add(const UpdateLanguageEvent('en')),
              ),
              const SizedBox(width: 8),
              _buildSegmentedButton(
                context: context,
                label: localizations.systemLanguage,
                icon: Icons.language_outlined,
                isSelected: settingsState.languageCode == 'system',
                onTap: () => context.read<SettingsBloc>().add(const UpdateLanguageEvent('system')),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // --- BACKGROUND NOTIFICATIONS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, size: 22, color: AppTheme.primary(context)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.notifications,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizations.notificationsDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsState.notificationsEnabled,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(ToggleNotificationsEvent(val));
                  },
                  activeThumbColor: AppTheme.primary(context),
                ),
              ],
            ),
          ),
          if (!kIsWeb && Platform.isWindows) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.menu_open_outlined, size: 22, color: AppTheme.primary(context)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.windowsMenu,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                localizations.windowsMenuDesc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsState.windowsMenuEnabled,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleWindowsMenuEvent(val));
                    },
                    activeThumbColor: AppTheme.primary(context),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          // --- DEFAULT OUTPUT PATH ---
          Text(
            localizations.defaultOutputPath,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Text(
                    converterState.savePath.isEmpty ? '/' : converterState.savePath,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.onSurfaceVariant(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _selectDirectory(context),
                icon: const Icon(Icons.folder_open_outlined, size: 16),
                label: Text(localizations.browse, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerLow(context),
                  foregroundColor: AppTheme.primary(context),
                  elevation: 0,
                  side: BorderSide(color: AppTheme.border(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a segmented control button with hover feedback and active styles.
  Widget _buildSegmentedButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.12) : AppTheme.surfaceContainerLowest(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary(context) : AppTheme.border(context),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a selectable circle representing a theme seed color.
  Widget _buildColorOption(
    BuildContext context,
    Color color,
    Color selectedColor,
    String tooltip,
  ) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.read<SettingsBloc>().add(UpdateThemeColorEvent(color));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Builds a details card showing tech specs, engine status, and environmental details.
  Widget _buildSystemInfoCard(BuildContext context, AppLocalizations localizations) {
    String platformName = 'Unknown';
    if (Platform.isWindows) {
      platformName = 'Windows Desktop';
    } else if (Platform.isAndroid) {
      platformName = 'Android Mobile';
    } else if (Platform.isLinux) {
      platformName = 'Linux Desktop';
    } else if (Platform.isMacOS) {
      platformName = 'macOS Desktop';
    } else if (Platform.isIOS) {
      platformName = 'iOS Mobile';
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 22, color: AppTheme.primary(context)),
              const SizedBox(width: 10),
              Text(
                localizations.systemInfo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // --- ENGINE STATUS ---
          _buildInfoRow(
            context: context,
            icon: Icons.settings_input_component_outlined,
            title: localizations.engineStatus,
            value: localizations.ffmpegActive,
            valueColor: AppTheme.success(context),
            valueFontWeight: FontWeight.bold,
          ),
          Divider(height: 24, thickness: 0.5, color: AppTheme.border(context)),

          // --- CODECS ---
          _buildInfoRow(
            context: context,
            icon: Icons.code,
            title: localizations.activeCodecs,
            value: localizations.activeCodecsDesc,
          ),
          Divider(height: 24, thickness: 0.5, color: AppTheme.border(context)),

          // --- PLATFORM ---
          _buildInfoRow(
            context: context,
            icon: Icons.devices_outlined,
            title: localizations.platform,
            value: platformName,
          ),
          Divider(height: 24, thickness: 0.5, color: AppTheme.border(context)),

          // --- APP VERSION ---
          _buildInfoRow(
            context: context,
            icon: Icons.verified_user_outlined,
            title: localizations.morphVersion,
            value: 'v1.0.0 (Pro-Convert Engine)',
          ),
          Divider(height: 24, thickness: 0.5, color: AppTheme.border(context)),

          // --- SOFTWARE TYPE ---
          _buildInfoRow(
            context: context,
            icon: Icons.favorite_border_outlined,
            title: localizations.freeSoftware,
            value: localizations.freeSoftwareDesc,
            valueColor: AppTheme.primary(context),
          ),
        ],
      ),
    );
  }

  /// Builds a single parameter row within the System Info card.
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: valueFontWeight ?? FontWeight.w500,
                  color: valueColor ?? AppTheme.onSurface(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<ConverterBloc, ConverterState>(
          builder: (context, converterState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 850;

                if (isDesktop) {
                  // Desktop split layout (Preferences Left, System Info Right)
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Preferences column
                            Expanded(
                              flex: 6,
                              child: _buildPreferencesCard(
                                context,
                                settingsState,
                                converterState,
                                localizations,
                              ),
                            ),
                            const SizedBox(width: 32),
                            // System info column
                            Expanded(
                              flex: 5,
                              child: _buildSystemInfoCard(context, localizations),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Mobile stacked layout
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPreferencesCard(
                          context,
                          settingsState,
                          converterState,
                          localizations,
                        ),
                        const SizedBox(height: 16),
                        _buildSystemInfoCard(context, localizations),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
