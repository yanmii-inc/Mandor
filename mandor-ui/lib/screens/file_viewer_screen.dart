import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../widgets/mandor_widgets.dart';

class FileViewerScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;
  final String filePath;

  const FileViewerScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = FileParams(projectId: projectId, path: filePath);
    final metadataAsync = ref.watch(fileMetadataProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          filePath.split('/').last,
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 2,
      ),
      body: metadataAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading file info...'),
        error: (error, stack) => MandorErrorWidget(
          error: error,
          stackTrace: stack,
          onRetry: () => ref.refresh(fileMetadataProvider(params)),
        ),
        data: (metadata) => _FileContentView(
          projectId: projectId,
          filePath: filePath,
          metadata: metadata,
          params: params,
        ),
      ),
    );
  }
}

class _FileContentView extends ConsumerStatefulWidget {
  final String projectId;
  final String filePath;
  final FileMetadata metadata;
  final FileParams params;

  const _FileContentView({
    required this.projectId,
    required this.filePath,
    required this.metadata,
    required this.params,
  });

  @override
  ConsumerState<_FileContentView> createState() => _FileContentViewState();
}

class _FileContentViewState extends ConsumerState<_FileContentView> {
  final TextEditingController _controller = TextEditingController();
  bool _initialTextSet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.metadata.isText) {
      return _buildTextContent(context, ref, theme);
    }

    return _buildBinaryContent(theme);
  }

  Widget _buildTextContent(BuildContext context, WidgetRef ref, ThemeData theme) {
    final contentAsync = ref.watch(fileContentProvider(widget.params));

    return Column(
      children: [
        _buildMetadataBar(theme),
        Expanded(
          child: contentAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading content...'),
            error: (error, stack) {
              final theme = Theme.of(context);
              if (error.toString().contains('416') ||
                  error.toString().contains('too large')) {
                return _buildLargeFileMessage(theme);
              }
              return MandorErrorWidget(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.refresh(fileContentProvider(widget.params)),
              );
            },
            data: (content) {
              if (!_initialTextSet) {
                _controller.text = content;
                _initialTextSet = true;
              }
              return _buildEditableCodeView(theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBinaryContent(ThemeData theme) {
    return Column(
      children: [
        _buildMetadataBar(theme),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Binary file',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This file type cannot be displayed in the viewer.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeFileMessage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'File too large',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This file exceeds 5 MB and cannot be streamed directly.\nUse the Range header to download in chunks.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataBar(ThemeData theme) {
    final formatter = NumberFormat.compact();
    final dateFormatter = DateFormat('MMM d, yyyy HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surfaceContainer,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _metadataChip(
            icon: Icons.straighten,
            label: '${formatter.format(widget.metadata.size)} B',
            theme: theme,
          ),
          _metadataChip(
            icon: Icons.label,
            label: widget.metadata.mime,
            theme: theme,
          ),
          _metadataChip(
            icon: Icons.schedule,
            label: dateFormatter.format(widget.metadata.modifiedAt),
            theme: theme,
          ),
          if (widget.metadata.lineCount != null)
            _metadataChip(
              icon: Icons.format_list_numbered,
              label: '${widget.metadata.lineCount} lines',
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _metadataChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEditableCodeView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
