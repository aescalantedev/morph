import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:share_plus/share_plus.dart';

import 'package:morph/l10n/app_localizations.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
import '../../../converter/presentation/bloc/converter_state.dart';
import '../../../converter/presentation/bloc/converter_event.dart';
import '../../../converter/domain/entities/media_file.dart';
import '../../../converter/presentation/widgets/file_picker_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/file_opener_service.dart';
import '../../../../core/di/injection_container.dart' as di;

/// Redesigned premium DashboardPage matching the convertzone.com layout.
///
/// Features a responsive layout with:
/// - A Middle Column: Quick Convert dropzone area and Recommended Tools grid.
/// - A Right Column: Recent Activity Sidebar showing details and quick actions (view/share).
class DashboardPage extends StatefulWidget {
  /// Creates a [DashboardPage] widget.
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _selectedFilePath;
  String? _selectedFileName;
  int _selectedFileSize = 0;
  String _fileCategory = 'image';
  String _fileExtension = '';
  String _targetFormat = 'WEBP';
  bool _isDragging = false;

  final Map<String, List<String>> _allowedTargetFormats = {
    'image': ['WEBP', 'PNG', 'JPG', 'GIF', 'PDF'],
    'video': ['MP4', 'WEBM', 'GIF', 'MKV', 'MP3'],
    'audio': ['MP3', 'WAV', 'OGG', 'M4A', 'FLAC', 'AAC'],
  };

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          _handleSelectedFile(
            path: file.path!,
            name: file.name,
            size: file.size,
          );
        }
      }
    } catch (_) {}
  }

  void _handleSelectedFile({
    required String path,
    required String name,
    required int size,
  }) {
    final fileExt = name.contains('.') ? name.split('.').last : '';
    final extLower = fileExt.toLowerCase();

    String category = 'image';
    if (['mp4', 'webm', 'gif', 'mkv', 'avi', 'mov', 'flv', 'wmv'].contains(extLower)) {
      category = 'video';
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac'].contains(extLower)) {
      category = 'audio';
    }

    final selectedFormat = _allowedTargetFormats[category]!.firstWhere(
      (format) => format.toUpperCase() != fileExt.toUpperCase(),
      orElse: () => _allowedTargetFormats[category]!.first,
    );

    setState(() {
      _selectedFilePath = path;
      _selectedFileName = name;
      _selectedFileSize = size;
      _fileCategory = category;
      _fileExtension = fileExt.toUpperCase();
      _targetFormat = selectedFormat;
    });
  }

  void _convertFile() {
    if (_selectedFilePath == null || _selectedFileName == null) return;

    final mediaFile = MediaFile(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_selectedFilePath',
      name: _selectedFileName!,
      path: _selectedFilePath!,
      sizeBytes: _selectedFileSize,
      extension: _fileExtension,
      category: _fileCategory,
      targetFormat: _targetFormat.toLowerCase(),
    );

    // Update Bloc
    final bloc = context.read<ConverterBloc>();
    bloc.add(ClearQueueEvent());
    bloc.add(ChangeActiveToolEvent(_fileCategory));
    bloc.add(ChangeTargetFormatEvent(_targetFormat.toLowerCase()));
    bloc.add(AddFilesEvent([mediaFile]));
    bloc.add(StartConversionEvent());

    // Reset local selection
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileSize = 0;
    });

    // Navigate to convert tab
    context.go('/convert');
  }

  void _runRecommendedTool(String tool, String format) async {
    final bloc = context.read<ConverterBloc>();
    bloc.add(ClearQueueEvent());
    bloc.add(ChangeActiveToolEvent(tool));
    bloc.add(ChangeTargetFormatEvent(format));
    
    // Switch to Convert tab first
    context.go('/convert');
    
    // Small delay to let the page mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FilePickerHelper.pickFiles(context: Navigator.of(context).context, activeTool: tool);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 950;

            if (isDesktop) {
              return Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 2 (Middle) - Quick Convert and Recommended Tools
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conversor Rápido',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                    color: AppTheme.onSurface(context),
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildQuickConvertCard(localizations),
                            const SizedBox(height: 20),
                            _buildRecommendedToolsSection(localizations),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Column 3 (Right) - History sidebar
                    Expanded(
                      flex: 2,
                      child: _buildHistorySidebar(context, state.history, localizations),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile / Tablet stacked layout
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Conversor Rápido',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: AppTheme.onSurface(context),
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickConvertCard(localizations),
                    const SizedBox(height: 20),
                    _buildRecommendedToolsSection(localizations),
                    const SizedBox(height: 20),
                    _buildHistorySidebar(context, state.history, localizations),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildQuickConvertCard(AppLocalizations localizations) {
    return DropTarget(
      onDragEntered: (detail) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (detail) async {
        setState(() {
          _isDragging = false;
        });
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final path = file.path;
          try {
            final fileIo = File(path);
            if (await fileIo.exists()) {
              final length = await fileIo.length();
              _handleSelectedFile(
                path: path,
                name: file.name,
                size: length,
              );
            }
          } catch (_) {}
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedFilePath == null || _selectedFileName == null)
              // Dropzone Area
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickFile,
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: _isDragging ? AppTheme.primary(context) : AppTheme.border(context),
                      borderRadius: 16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: _isDragging ? AppTheme.primary(context) : AppTheme.primaryLight(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Arrastra tu archivo aquí',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface(context),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'o haz clic para explorar en el sistema',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant(context),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              // Selected File details
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _fileCategory == 'image'
                          ? Icons.image_outlined
                          : (_fileCategory == 'video' ? Icons.videocam_outlined : Icons.volume_up_outlined),
                      color: AppTheme.primary(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface(context),
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_fileExtension.toUpperCase()} • ${_formatBytes(_selectedFileSize)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant(context),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedFilePath = null;
                        _selectedFileName = null;
                        _selectedFileSize = 0;
                      });
                    },
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              // Target Format Selector
              Text(
                'Convertir a:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface(context),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allowedTargetFormats[_fileCategory]!
                    .where((format) => format.toUpperCase() != _fileExtension.toUpperCase())
                    .map((format) {
                  final isSelected = _targetFormat == format;
                  return ChoiceChip(
                    label: Text(format),
                    selected: isSelected,
                    selectedColor: AppTheme.primary(context).withValues(alpha: 0.15),
                    backgroundColor: AppTheme.surfaceContainerLow(context),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryLight(context) : const Color(0xFFA1A1AA),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.5) : AppTheme.border(context),
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _targetFormat = format;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Action Button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _convertFile,
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text(
                    'Convertir Ahora',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedToolsSection(AppLocalizations localizations) {
    final tools = [
      {'name': 'PNG a PDF', 'tool': 'image', 'format': 'pdf', 'icon': Icons.picture_as_pdf_outlined},
      {'name': 'PDF a PNG', 'tool': 'image', 'format': 'png', 'icon': Icons.image_outlined},
      {'name': 'Video a MP3', 'tool': 'video', 'format': 'mp3', 'icon': Icons.music_note_outlined},
      {'name': 'Imagen a WebP', 'tool': 'image', 'format': 'webp', 'icon': Icons.photo_library_outlined},
      {'name': 'Video a WebM', 'tool': 'video', 'format': 'webm', 'icon': Icons.video_library_outlined},
      {'name': 'Audio a WAV', 'tool': 'audio', 'format': 'wav', 'icon': Icons.audiotrack_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth >= 580 ? 3 : 2;
        final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;
        final double childAspectRatio = itemWidth / 72;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Herramientas Recomendadas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: AppTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return InkWell(
                  onTap: () => _runRecommendedTool(tool['tool'] as String, tool['format'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tool['icon'] as IconData,
                            size: 18,
                            color: AppTheme.primary(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tool['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface(context),
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Acceso rápido instantáneo',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.onSurfaceVariant(context),
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorySidebar(BuildContext context, List<MediaFile> history, AppLocalizations localizations) {
    final completedItems = history.where((f) => f.status == ConversionStatus.completed || f.status == ConversionStatus.failed).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial Reciente',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: AppTheme.onSurface(context),
                ),
              ),
              if (completedItems.isNotEmpty)
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: Text(
                    'Ver Todo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary(context),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (completedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 36, color: AppTheme.outline(context)),
                    const SizedBox(height: 12),
                    Text(
                      'No hay archivos convertidos',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant(context),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedItems.length.clamp(0, 6),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = completedItems[index];
                final isFailed = item.status == ConversionStatus.failed;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFailed
                              ? AppTheme.error(context).withValues(alpha: 0.08)
                              : AppTheme.success(context).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFailed
                              ? Icons.error_outline
                              : (item.category == 'image'
                                  ? Icons.image_outlined
                                  : (item.category == 'video' ? Icons.videocam_outlined : Icons.volume_up_outlined)),
                          size: 16,
                          color: isFailed ? AppTheme.error(context) : AppTheme.success(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface(context),
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFailed
                                  ? 'Fallido'
                                  : '${item.extension.toUpperCase()} ➔ ${item.targetFormat.toUpperCase()} • ${_formatBytes(item.sizeBytes)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isFailed ? AppTheme.error(context) : AppTheme.onSurfaceVariant(context),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isFailed && item.outputPath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 14),
                          onPressed: () {
                            di.sl<FileOpenerService>().openFile(item.outputPath!);
                          },
                          splashRadius: 16,
                          tooltip: 'Abrir archivo',
                          color: AppTheme.primary(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 14),
                          onPressed: () {
                            try {
                              Share.shareXFiles([XFile(item.outputPath!)], text: 'Convertido con Morph');
                            } catch (_) {}
                          },
                          splashRadius: 16,
                          tooltip: 'Compartir',
                          color: AppTheme.onSurfaceVariant(context),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Custom painter to draw beautiful dashed borders for the dropzone container.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.borderRadius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
