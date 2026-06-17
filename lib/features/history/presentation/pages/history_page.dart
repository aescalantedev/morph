import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../converter/domain/entities/media_file.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
import '../../../converter/presentation/bloc/converter_event.dart';
import '../../../converter/presentation/bloc/converter_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../services/file_opener_service.dart';

/// A page displaying all historical file conversions in the current session.
///
/// Subscribes to the [ConverterBloc] state and displays completed and failed
/// conversions, with source formats, output targets, file locations, and errors.
class HistoryPage extends StatefulWidget {
  /// Creates a [HistoryPage] widget.
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isTransitioning = true;

  @override
  void initState() {
    super.initState();
    // Dispatch LoadHistoryEvent to refresh or load it in case it hasn't been loaded
    context.read<ConverterBloc>().add(const LoadHistoryEvent());
    
    // Defer rendering the real list to avoid first-build layout jank during tab transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds a status badge representing the outcome of the conversion (completed/failed).
  Widget _buildStatusBadge(BuildContext context, ConversionStatus status, AppLocalizations localizations) {
    Color color = AppTheme.primary(context);
    String text = localizations.processing;
    IconData icon = Icons.sync;

    if (status == ConversionStatus.completed) {
      color = AppTheme.success(context);
      text = localizations.completed;
      icon = Icons.check_circle;
    } else if (status == ConversionStatus.failed) {
      color = AppTheme.error(context);
      text = localizations.failed;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary(context).withValues(alpha: 0.15),
      backgroundColor: AppTheme.surface(context),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryLight(context) : const Color(0xFFA1A1AA),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.5) : AppTheme.border(context),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        final history = state.history;

        // Apply filters
        final filteredHistory = history.where((item) {
          if (_selectedCategory != 'all' && item.category != _selectedCategory) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesName = item.name.toLowerCase().contains(query);
            final matchesPath = item.outputPath?.toLowerCase().contains(query) ?? false;
            return matchesName || matchesPath;
          }
          return true;
        }).toList();

        // Responsive filters UI
        final filterSection = LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final searchField = SizedBox(
              width: isWide ? 280 : double.infinity,
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar archivo...',
                  hintStyle: TextStyle(color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.onSurfaceVariant(context)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary(context)),
                  ),
                ),
              ),
            );

            final chips = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('image', 'Imágenes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('video', 'Videos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('audio', 'Audios'),
                ],
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  searchField,
                  const SizedBox(width: 16),
                  Expanded(child: chips),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  chips,
                ],
              );
            }
          },
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (history.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.recentActivity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface(context),
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<ConverterBloc>().add(const ClearHistoryEvent());
                      },
                      icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.error(context)),
                      label: Text(
                        localizations.clearHistory,
                        style: TextStyle(color: AppTheme.error(context), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                filterSection,
                const SizedBox(height: 16),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: (_isTransitioning || !state.isHistoryLoaded)
                        ? const _HistorySkeleton(key: ValueKey('skeleton'))
                        : history.isEmpty
                            ? Center(
                                key: const ValueKey('empty'),
                                child: Text(
                                  localizations.historyEmpty,
                                  style: TextStyle(color: AppTheme.onSurfaceVariant(context), fontSize: 13),
                                ),
                              )
                            : filteredHistory.isEmpty
                                ? Center(
                                    key: const ValueKey('no-results'),
                                    child: Text(
                                      'No se encontraron resultados.',
                                      style: TextStyle(color: AppTheme.onSurfaceVariant(context), fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    key: const ValueKey('list'),
                                    itemCount: filteredHistory.length,
                                    separatorBuilder: (context, index) => Divider(color: AppTheme.border(context), height: 1),
                                    itemBuilder: (context, index) {
                                      final item = filteredHistory[index];
                                      IconData itemIcon = Icons.insert_drive_file_outlined;
                                      if (item.category == 'image') {
                                        itemIcon = Icons.image_outlined;
                                      } else if (item.category == 'video') {
                                        itemIcon = Icons.videocam_outlined;
                                      } else if (item.category == 'audio') {
                                        itemIcon = Icons.volume_up_outlined;
                                      }

                                      final isCompleted = item.status == ConversionStatus.completed;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        child: Row(
                                          key: ValueKey(item.id),
                                          children: [
                                            Icon(itemIcon, color: AppTheme.onSurfaceVariant(context), size: 22),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppTheme.onSurface(context),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (item.outputPath != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.outputPath!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppTheme.onSurfaceVariant(context),
                                                        fontFamily: 'monospace',
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  if (item.errorMessage != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.errorMessage!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppTheme.error(context),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Format badge (FROM -> TO)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.canvas(context),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppTheme.border(context)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item.extension,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontFamily: 'monospace',
                                                      color: AppTheme.onSurfaceVariant(context),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.arrow_right_alt, size: 10, color: AppTheme.outline(context)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.targetFormat.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontFamily: 'monospace',
                                                      color: AppTheme.primaryLight(context),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildStatusBadge(context, item.status, localizations),
                                            if (isCompleted && item.outputPath != null) ...[
                                              const SizedBox(width: 16),
                                              IconButton(
                                                icon: const Icon(Icons.open_in_new, size: 16),
                                                onPressed: () {
                                                  di.sl<FileOpenerService>().openFile(item.outputPath!);
                                                },
                                                tooltip: 'Abrir archivo',
                                                splashRadius: 20,
                                                constraints: const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                                color: AppTheme.primary(context),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                icon: const Icon(Icons.share_outlined, size: 16),
                                                onPressed: () {
                                                  try {
                                                    //Share.shareXFiles([XFile(item.outputPath!)], text: 'Convertido con Morph');
                                                    SharePlus.instance.share(
                                                      ShareParams(files: [XFile(item.outputPath!)], text: 'Convertido con Morph'),
                                                    );
                                                  } catch (_) {}
                                                },
                                                tooltip: 'Compartir',
                                                splashRadius: 20,
                                                constraints: const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                                color: AppTheme.onSurfaceVariant(context),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A premium pulsating skeleton loader for History items to prevent first-build jank.
class _HistorySkeleton extends StatefulWidget {
  const _HistorySkeleton({super.key});

  @override
  State<_HistorySkeleton> createState() => _HistorySkeletonState();
}

class _HistorySkeletonState extends State<_HistorySkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(color: AppTheme.border(context), height: 1),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Icon Placeholder
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Subtitle placeholders
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Format badge placeholder
                    Container(
                      width: 65,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Badge Placeholder
                    Container(
                      width: 70,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
