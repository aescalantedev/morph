import 'package:flutter/material.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_file.dart';

/// A widget that displays the summary of a completed file conversion run.
///
/// Presents success metrics (how many completed or failed) and the output paths
/// of the successfully converted files, with a reset button.
class ConversionProgress extends StatelessWidget {
  /// The list of converted files.
  final List<MediaFile> queue;

  /// The path to the generated ZIP archive, if any.
  final String? generatedZipPath;

  /// Callback when the user wishes to return to the idle converter screen.
  final VoidCallback onReset;

  /// Creates a [ConversionProgress] widget.
  const ConversionProgress({
    super.key,
    required this.queue,
    this.generatedZipPath,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final successfulConversions = queue.where((f) => f.status == ConversionStatus.completed).toList();
    final failedConversions = queue.where((f) => f.status == ConversionStatus.failed).toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Circle Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.conversionSuccess,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${successfulConversions.length} ${localizations.completed.toLowerCase()} • ${failedConversions.length} ${localizations.failed.toLowerCase()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (generatedZipPath != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.localeName == 'es' ? 'Archivo ZIP Creado' : 'ZIP File Created',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(
                          generatedZipPath!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Output files list
              if (successfulConversions.isNotEmpty) ...[
                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),
                ...successfulConversions.map((file) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (file.outputPath != null)
                                Text(
                                  file.outputPath!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              // Failed files list
              if (failedConversions.isNotEmpty) ...[
                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),
                ...failedConversions.map((file) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (file.errorMessage != null)
                                Text(
                                  file.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.error,
                                  ),
                                  maxLines: 15,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              const Divider(color: AppTheme.border),
              const SizedBox(height: 24),
              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.convertAnother,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
