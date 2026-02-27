import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/book_model.dart';
import '../models/extraction_result.dart';
import '../providers/epub_providers.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive.dart';
import '../widgets/extraction_status_widget.dart';
import '../widgets/image_grid.dart';

/// The main screen of the application
class HomeScreen extends HookConsumerWidget {
  /// Creates a new HomeScreen instance
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEpub = ref.watch(selectedEpubProvider);
    final extractionState = ref.watch(extractionStateProvider);
    final isSaving = ref.watch(isSavingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Image Extractor'),
        actions: const [_ThemeModeButton()],
      ),
      body: Responsive.hasSidebar(context)
          ? _buildSidebarBody(context, ref, selectedEpub, extractionState, isSaving)
          : _buildPhoneBody(context, ref, selectedEpub, extractionState, isSaving),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout — stacked single-column
  // ---------------------------------------------------------------------------

  Widget _buildPhoneBody(
    BuildContext context,
    WidgetRef ref,
    BookModel? selectedEpub,
    ExtractionResult? extractionState,
    bool isSaving,
  ) {
    final images = extractionState?.isSuccess == true ? extractionState?.images : null;
    final padding = Responsive.contentPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding.copyWith(bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBookInfoSection(context, ref, selectedEpub, isPhone: true),
              const SizedBox(height: 8),
              if (extractionState != null || isSaving)
                ExtractionStatusWidget(
                  extractionState: extractionState ??
                      ExtractionResult.inProgress(message: 'Saving images...'),
                  isExtracting: extractionState?.isInProgress ?? false,
                  isSaving: isSaving,
                ),
              if (extractionState != null || isSaving) const SizedBox(height: 8),
              if (selectedEpub != null)
                _buildPhoneActionButtons(context, ref, selectedEpub, extractionState),
              if (selectedEpub != null) const SizedBox(height: 8),
            ],
          ),
        ),
        if (images != null)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: padding.left, right: padding.right, bottom: padding.bottom),
              child: ImageGrid(
                images: images,
                crossAxisCount: Responsive.gridColumns(context),
                cacheImageWidth: Responsive.imageCacheWidth(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneActionButtons(
    BuildContext context,
    WidgetRef ref,
    BookModel epubBook,
    ExtractionResult? extractionState,
  ) {
    final canExtract = extractionState == null || !extractionState.isInProgress;
    final canSave = extractionState?.isSuccess == true &&
        extractionState?.images != null &&
        extractionState!.images!.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.image_search),
            label: const Text('Extract Images'),
            onPressed: canExtract ? () => extractImages(ref) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_alt),
            label: const Text('Save All Images'),
            onPressed: canSave ? () => _onSaveAll(context, ref) : null,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet / Desktop layout — sidebar + content
  // ---------------------------------------------------------------------------

  Widget _buildSidebarBody(
    BuildContext context,
    WidgetRef ref,
    BookModel? selectedEpub,
    ExtractionResult? extractionState,
    bool isSaving,
  ) {
    final sidebarWidth = Responsive.sidebarWidth(context);
    final padding = Responsive.contentPadding(context);
    final images = extractionState?.isSuccess == true ? extractionState?.images : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sidebar
        SizedBox(
          width: sidebarWidth,
          child: ColoredBox(
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBookInfoSection(context, ref, selectedEpub, isPhone: false),
                        if (extractionState != null || isSaving) ...[
                          const SizedBox(height: 16),
                          ExtractionStatusWidget(
                            extractionState: extractionState ??
                                ExtractionResult.inProgress(message: 'Saving images...'),
                            isExtracting: extractionState?.isInProgress ?? false,
                            isSaving: isSaving,
                          ),
                        ],
                        if (selectedEpub != null) ...[
                          const SizedBox(height: 16),
                          _buildSidebarActionButtons(context, ref, selectedEpub, extractionState),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vertical divider
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
        // Content area
        Expanded(
          child: _buildContentArea(context, images, padding),
        ),
      ],
    );
  }

  Widget _buildSidebarActionButtons(
    BuildContext context,
    WidgetRef ref,
    BookModel epubBook,
    ExtractionResult? extractionState,
  ) {
    final canExtract = extractionState == null || !extractionState.isInProgress;
    final canSave = extractionState?.isSuccess == true &&
        extractionState?.images != null &&
        extractionState!.images!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.image_search),
          label: const Text('Extract Images'),
          onPressed: canExtract ? () => extractImages(ref) : null,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.save_alt),
          label: const Text('Save All Images'),
          onPressed: canSave ? () => _onSaveAll(context, ref) : null,
        ),
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    List<BookImage>? images,
    EdgeInsets padding,
  ) {
    if (images == null) {
      return _buildEmptyContentState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 8),
          child: Text(
            '${images.length} image${images.length == 1 ? '' : 's'} found',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, padding.bottom),
            child: ImageGrid(
              images: images,
              crossAxisCount: Responsive.gridColumns(context),
              cacheImageWidth: Responsive.imageCacheWidth(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContentState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 72,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No images extracted yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an EPUB and tap Extract Images',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared — book info section
  // ---------------------------------------------------------------------------

  Widget _buildBookInfoSection(
    BuildContext context,
    WidgetRef ref,
    BookModel? epubBook, {
    required bool isPhone,
  }) {
    if (epubBook == null) {
      return _buildNoBookSection(context, ref, isPhone: isPhone);
    }
    return _buildBookInfoCard(
      context,
      epubBook,
      isPhone: isPhone,
      onSelectAnother: () => selectEpub(ref),
    );
  }

  Widget _buildNoBookSection(
    BuildContext context,
    WidgetRef ref, {
    required bool isPhone,
  }) {
    if (isPhone) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select an EPUB file to extract images',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('Select EPUB'),
                onPressed: () => selectEpub(ref),
              ),
            ],
          ),
        ),
      );
    }

    // Sidebar variant — compact
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Select an EPUB file to extract images',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.file_open),
          label: const Text('Select EPUB'),
          onPressed: () => selectEpub(ref),
        ),
      ],
    );
  }

  Widget _buildBookInfoCard(
    BuildContext context,
    BookModel epubBook, {
    required bool isPhone,
    VoidCallback? onSelectAnother,
  }) {
    if (isPhone) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${epubBook.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (epubBook.author != null)
                Text(
                  'Author: ${epubBook.author}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 8),
              Text('File: ${epubBook.filePath}'),
              if (onSelectAnother != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Change EPUB'),
                    onPressed: onSelectAnother,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Sidebar variant — no card wrapper, uses the sidebar background
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                epubBook.title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (epubBook.author != null) ...[
          const SizedBox(height: 6),
          Text(
            epubBook.author!,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          epubBook.filePath,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (onSelectAnother != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Change EPUB'),
            onPressed: onSelectAnother,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared — save action with SnackBar feedback
  // ---------------------------------------------------------------------------

  Future<void> _onSaveAll(BuildContext context, WidgetRef ref) async {
    await saveImages(ref);
    if (!context.mounted) return;
    final result = ref.read(extractionStateProvider);
    if (result?.isSuccess == true && result?.outputPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All images saved to ${result!.outputPath}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }
}

class _ThemeModeButton extends ConsumerWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      icon: Icon(_iconFor(themeMode)),
      tooltip: 'Theme',
      onSelected: (mode) => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: ThemeMode.light,
          child: _ThemeOption(icon: Icons.light_mode, label: 'Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: _ThemeOption(icon: Icons.dark_mode, label: 'Dark'),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: _ThemeOption(icon: Icons.brightness_auto, label: 'System'),
        ),
      ],
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
        ThemeMode.system => Icons.brightness_auto,
      };
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
