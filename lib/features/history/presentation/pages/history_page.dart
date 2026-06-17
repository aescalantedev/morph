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
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            localizations.historyEmpty,
                            style: TextStyle(color: AppTheme.onSurfaceVariant(context), fontSize: 13),
                          ),
                        )
                      : filteredHistory.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron resultados.',
                                style: TextStyle(color: AppTheme.onSurfaceVariant(context), fontSize: 13),
                              ),
                            )
                          : ListView.separated(
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
                                              Share.shareXFiles([XFile(item.outputPath!)], text: 'Convertido con Morph');
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
            ],
          ),
        );
      },
    );
  }
}
