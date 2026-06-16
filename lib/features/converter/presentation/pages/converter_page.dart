import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_file.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';
import '../widgets/dropzone_area.dart';
import '../widgets/file_card.dart';
import '../widgets/settings_panel.dart';
import '../widgets/conversion_progress.dart';

/// The page containing the media converter queue, format settings, and dropzone.
///
/// Automatically switches between desktop (side-by-side) and mobile (stacked) layouts.
/// Displays a success recap screen once all conversions have finished.
class ConverterPage extends StatelessWidget {
  /// Creates a [ConverterPage] widget.
  const ConverterPage({super.key});

  /// Builds the top tabs to switch between conversion tools (Image, Video, Audio).
  Widget _buildToolTabs(BuildContext context, String activeTool, bool isConverting, AppLocalizations localizations) {
    final tools = [
      {'id': 'image', 'name': localizations.images, 'icon': Icons.image_outlined},
      {'id': 'video', 'name': localizations.video, 'icon': Icons.videocam_outlined},
      {'id': 'audio', 'name': localizations.audio, 'icon': Icons.volume_up_outlined},
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: tools.map((tool) {
          final isSelected = activeTool == tool['id'];
          return Expanded(
            child: MouseRegion(
              cursor: isConverting ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isConverting
                    ? null
                    : () {
                        context.read<ConverterBloc>().add(ChangeActiveToolEvent(tool['id'] as String));
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.2) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool['icon'] as IconData,
                        size: 16,
                        color: isSelected ? AppTheme.primaryLight(context) : const Color(0xFFA1A1AA),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tool['name'] as String,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryLight(context) : const Color(0xFFA1A1AA),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        // Check if conversion completed successfully (queue not empty and all finished)
        final bool showSuccessScreen = state.queue.isNotEmpty &&
            !state.isConverting &&
            state.queue.every((f) => f.status == ConversionStatus.completed || f.status == ConversionStatus.failed);

        if (showSuccessScreen) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ConversionProgress(
              queue: state.queue,
              generatedZipPath: state.generatedZipPath,
              onReset: () {
                context.read<ConverterBloc>().add(ResetConverterEvent());
              },
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            final Widget activeWidget = state.queue.isEmpty
                ? DropzoneArea(activeTool: state.activeTool)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.queue.length,
                    itemBuilder: (context, index) {
                      final file = state.queue[index];
                      return FileCard(
                        file: file,
                        isConverting: state.isConverting,
                        onRemove: () {
                          context.read<ConverterBloc>().add(RemoveFileEvent(file.id));
                        },
                      );
                    },
                  );

            if (isDesktop) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildToolTabs(context, state.activeTool, state.isConverting, localizations),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left queue list
                        Expanded(
                          flex: 3,
                          child: activeWidget,
                        ),
                        if (state.queue.isNotEmpty) ...[
                          const SizedBox(width: 24),
                          // Right settings panel
                          Expanded(
                            flex: 2,
                            child: SettingsPanel(
                              activeTool: state.activeTool,
                              targetFormat: state.targetFormat,
                              quality: state.quality,
                              savePath: state.savePath,
                              isConverting: state.isConverting,
                              queueLength: state.queue.length,
                              shouldZip: state.shouldZip,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            } else {
              // Mobile/Tablet stacked layout
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildToolTabs(context, state.activeTool, state.isConverting, localizations),
                    const SizedBox(height: 24),
                    activeWidget,
                    if (state.queue.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SettingsPanel(
                        activeTool: state.activeTool,
                        targetFormat: state.targetFormat,
                        quality: state.quality,
                        savePath: state.savePath,
                        isConverting: state.isConverting,
                        queueLength: state.queue.length,
                        shouldZip: state.shouldZip,
                      ),
                    ],
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
