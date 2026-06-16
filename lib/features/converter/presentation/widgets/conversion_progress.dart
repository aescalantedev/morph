import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../../services/file_opener_service.dart';
import '../../domain/entities/media_file.dart';

/// A widget that displays the summary of a completed file conversion run.
///
/// Presents success metrics (how many completed or failed) and the output paths
/// of the successfully converted files, with a responsive layout.
class ConversionProgress extends StatelessWidget {
  /// The list of converted files.
  final List<MediaFile> queue;

  /// The path to the generated ZIP archive, if any.
  final String? generatedZipPath;

  /// Callback when the user wishes to return to the idle converter screen.
  final VoidCallback onReset;

  /// Signals whether the files were merged into a single output file.
  final bool mergeIntoSingleFile;

  /// Creates a [ConversionProgress] widget.
  const ConversionProgress({
    super.key,
    required this.queue,
    this.generatedZipPath,
    required this.onReset,
    this.mergeIntoSingleFile = false,
  });

  /// Formats byte size into readable string units (e.g. '3.5 MB').
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  IconData _getFileIcon(String category) {
    if (category == 'image') {
      return Icons.image_outlined;
    } else if (category == 'video') {
      return Icons.videocam_outlined;
    } else if (category == 'audio') {
      return Icons.volume_up_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _shareFiles(List<MediaFile> successfulConversions) async {
    final List<String> pathsToShare = [];
    if (generatedZipPath != null) {
      pathsToShare.add(generatedZipPath!);
    } else {
      // Use toSet() to avoid sharing the same merged file multiple times
      pathsToShare.addAll(successfulConversions.map((f) => f.outputPath).whereType<String>().toSet());
    }

    if (pathsToShare.isNotEmpty) {
      try {
        final List<XFile> xFiles = pathsToShare.map((p) => XFile(p)).toList();
        await Share.shareXFiles(xFiles, text: 'Convertido con Morph');
      } catch (e) {
        debugPrint('Error sharing files: $e');
      }
    }
  }

  Widget _buildZipSection(BuildContext context, AppLocalizations localizations) {
    if (generatedZipPath == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primaryLight(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.localeName == 'es' ? 'Archivo ZIP Creado' : 'ZIP File Created',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryLight(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    generatedZipPath!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant(context),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: localizations.localeName == 'es' ? 'Abrir ZIP' : 'Open ZIP',
                onPressed: () {
                  di.sl<FileOpenerService>().openFile(generatedZipPath!);
                },
              ),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                tooltip: localizations.localeName == 'es' ? 'Mostrar en carpeta' : 'Show in folder',
                onPressed: () {
                  di.sl<FileOpenerService>().openFolder(generatedZipPath!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMergedPdfItemDesktop(BuildContext context, String mergedPath, int totalSize, AppLocalizations localizations) {
    final fileName = mergedPath.split(Platform.pathSeparator).last;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.success(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 18,
              color: AppTheme.success(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.images.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 10, color: AppTheme.onSurfaceVariant(context)),
                    const SizedBox(width: 4),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(totalSize),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: AppTheme.success(context)),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  di.sl<FileOpenerService>().openFile(mergedPath);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  localizations.viewFile,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  di.sl<FileOpenerService>().openFolder(mergedPath);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  localizations.openFolder,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMergedPdfItemMobile(BuildContext context, String mergedPath, int totalSize, AppLocalizations localizations) {
    final fileName = mergedPath.split(Platform.pathSeparator).last;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.success(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: AppTheme.success(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatBytes(totalSize),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  PDF (${localizations.localeName == 'es' ? 'Combinado' : 'Merged'})',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppTheme.success(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  di.sl<FileOpenerService>().openFile(mergedPath);
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(localizations.viewFile, style: const TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  di.sl<FileOpenerService>().openFolder(mergedPath);
                },
                icon: const Icon(Icons.folder_open_outlined, size: 14),
                label: Text(localizations.openFolder, style: const TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileItemDesktop(BuildContext context, MediaFile file, AppLocalizations localizations) {
    final bool isCompleted = file.status == ConversionStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          // Left: Category icon + name
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.success(context).withValues(alpha: 0.08)
                  : AppTheme.error(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getFileIcon(file.category),
              size: 18,
              color: isCompleted ? AppTheme.success(context) : AppTheme.error(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompleted && file.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      file.errorMessage!,
                      style: TextStyle(fontSize: 11, color: AppTheme.error(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Middle: Transformation + Size
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.extension.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant(context),
                      ),
                    ),
                    if (isCompleted && file.targetFormat.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 10, color: AppTheme.onSurfaceVariant(context)),
                      const SizedBox(width: 4),
                      Text(
                        file.targetFormat.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight(context),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(file.sizeBytes),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant(context),
                  ),
                ),
              ],
            ),
          ),
          // Right: Check badge + Action buttons
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted) ...[
                Icon(Icons.check_circle, size: 16, color: AppTheme.success(context)),
                const SizedBox(width: 12),
                if (file.outputPath != null) ...[
                  TextButton(
                    onPressed: () {
                      di.sl<FileOpenerService>().openFile(file.outputPath!);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      localizations.viewFile,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      di.sl<FileOpenerService>().openFolder(file.outputPath!);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      localizations.openFolder,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ] else ...[
                Icon(Icons.error_outline, size: 16, color: AppTheme.error(context)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileItemMobile(BuildContext context, MediaFile file, AppLocalizations localizations) {
    final bool isCompleted = file.status == ConversionStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.success(context).withValues(alpha: 0.08)
                      : AppTheme.error(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(file.category),
                  size: 16,
                  color: isCompleted ? AppTheme.success(context) : AppTheme.error(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatBytes(file.sizeBytes),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${file.extension.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant(context),
                          ),
                        ),
                        if (isCompleted && file.targetFormat.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 9, color: AppTheme.onSurfaceVariant(context)),
                          const SizedBox(width: 4),
                          Text(
                            file.targetFormat.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: isCompleted ? AppTheme.success(context) : AppTheme.error(context),
              ),
            ],
          ),
          if (isCompleted && file.outputPath != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    di.sl<FileOpenerService>().openFile(file.outputPath!);
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(localizations.viewFile, style: const TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    di.sl<FileOpenerService>().openFolder(file.outputPath!);
                  },
                  icon: const Icon(Icons.folder_open_outlined, size: 14),
                  label: Text(localizations.openFolder, style: const TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
          if (!isCompleted && file.errorMessage != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                file.errorMessage!,
                style: TextStyle(fontSize: 10, color: AppTheme.error(context)),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations localizations) {
    final successfulConversions = queue.where((f) => f.status == ConversionStatus.completed).toList();
    final failedConversions = queue.where((f) => f.status == ConversionStatus.failed).toList();

    final String? mergedPdfPath = mergeIntoSingleFile && successfulConversions.isNotEmpty
        ? successfulConversions.first.outputPath
        : null;
    int mergedPdfSize = 0;
    if (mergedPdfPath != null) {
      try {
        mergedPdfSize = File(mergedPdfPath).lengthSync();
      } catch (_) {
        mergedPdfSize = successfulConversions.fold(0, (sum, f) => sum + f.sizeBytes);
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          decoration: BoxDecoration(
            color: AppTheme.surface(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Center check circle header
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.success(context).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 38,
                        color: AppTheme.success(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.conversionComplete,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${successfulConversions.length} ${localizations.completed.toLowerCase()} • ${failedConversions.length} ${localizations.failed.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant(context),
                          ),
                    ),
                    const SizedBox(height: 28),
                    _buildZipSection(context, localizations),
                    // Files List
                    Flexible(
                      child: mergedPdfPath != null
                          ? _buildMergedPdfItemDesktop(context, mergedPdfPath, mergedPdfSize, localizations)
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: queue.length,
                              itemBuilder: (context, index) {
                                return _buildFileItemDesktop(context, queue[index], localizations);
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    // Action button at bottom
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          localizations.convertAnother,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary(context),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Close button on top-right
              Positioned(
                top: 16,
                right: 16,
                child: ClipOval(
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: AppTheme.onSurfaceVariant(context),
                      onPressed: onReset,
                      splashRadius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations localizations) {
    final successfulConversions = queue.where((f) => f.status == ConversionStatus.completed).toList();
    final failedConversions = queue.where((f) => f.status == ConversionStatus.failed).toList();

    final String? mergedPdfPath = mergeIntoSingleFile && successfulConversions.isNotEmpty
        ? successfulConversions.first.outputPath
        : null;
    int mergedPdfSize = 0;
    if (mergedPdfPath != null) {
      try {
        mergedPdfSize = File(mergedPdfPath).lengthSync();
      } catch (_) {
        mergedPdfSize = successfulConversions.fold(0, (sum, f) => sum + f.sizeBytes);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          localizations.conversionComplete,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onReset,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header status
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.success(context).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 34,
                      color: AppTheme.success(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.conversionSuccess,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${successfulConversions.length} ${localizations.completed.toLowerCase()} • ${failedConversions.length} ${localizations.failed.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildZipSection(context, localizations),
            // Files List
            mergedPdfPath != null
                ? _buildMergedPdfItemMobile(context, mergedPdfPath, mergedPdfSize, localizations)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      return _buildFileItemMobile(context, queue[index], localizations);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(
            top: BorderSide(color: AppTheme.border(context)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Open folder button (Primary)
              if (successfulConversions.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final firstOutput = successfulConversions.first.outputPath;
                      if (firstOutput != null) {
                        di.sl<FileOpenerService>().openFolder(firstOutput);
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      localizations.openFolder,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (successfulConversions.isNotEmpty) const SizedBox(height: 12),
              // Share and Convert another side by side
              Row(
                children: [
                  if (successfulConversions.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareFiles(successfulConversions),
                          icon: const Icon(Icons.share_outlined, size: 16),
                          label: Text(localizations.share, style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface(context),
                            side: BorderSide(color: AppTheme.border(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          localizations.localeName == 'es' ? 'Otro' : 'Another',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.onSurface(context),
                          side: BorderSide(color: AppTheme.border(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    if (isDesktop) {
      return _buildDesktopLayout(context, localizations);
    } else {
      return _buildMobileLayout(context, localizations);
    }
  }
}
