import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../widgets/mandor_widgets.dart';
import 'file_viewer_screen.dart';

class _TreeNode {
  final String name;
  final String path;
  final bool isDirectory;
  bool isExpanded = false;
  bool isLoading = false;
  List<_TreeNode>? children;

  _TreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
  });
}

class _FlatNode {
  final _TreeNode node;
  final int depth;

  const _FlatNode(this.node, this.depth);
}

class FileBrowserScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final String initialPath;

  const FileBrowserScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialPath = '',
  });

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  String _currentPath = '';
  List<_TreeNode> _treeRoots = [];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
  }

  void _navigateTo(String path) {
    setState(() => _currentPath = path);
  }

  void _navigateUp() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    _navigateTo(parts.join('/'));
  }

  void _navigateToBreadcrumb(int index) {
    if (index == 0) {
      _navigateTo('');
    } else {
      final parts = _currentPath.split('/');
      _navigateTo(parts.take(index).join('/'));
    }
  }

  List<_FlatNode> _flattenTree() {
    final result = <_FlatNode>[];
    for (final node in _treeRoots) {
      _flattenNode(node, 0, result);
    }
    return result;
  }

  void _flattenNode(_TreeNode node, int depth, List<_FlatNode> result) {
    result.add(_FlatNode(node, depth));
    if (node.isExpanded && node.children != null) {
      for (final child in node.children!) {
        _flattenNode(child, depth + 1, result);
      }
    }
  }

  Future<void> _reloadTree() async {
    final client = ref.read(mandorApiClientProvider);
    try {
      final entries = await client.browseDirectory(widget.projectId, '.');
      setState(() {
        _treeRoots = entries.map((e) => _TreeNode(
          name: e.name,
          path: e.name,
          isDirectory: e.isDirectory,
        )).toList();
      });
    } catch (e) {
      // Tree will show error state on next build
      setState(() => _treeRoots = []);
    }
  }

  void _onTreeRefresh() {
    _treeRoots = [];
    _reloadTree();
  }

  Future<void> _toggleTreeNode(_TreeNode node) async {
    if (!node.isDirectory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerScreen(
            projectId: widget.projectId,
            projectName: widget.projectName,
            filePath: node.path,
          ),
        ),
      );
      return;
    }

    if (node.children != null) {
      setState(() => node.isExpanded = !node.isExpanded);
      return;
    }

    setState(() => node.isLoading = true);
    try {
      final client = ref.read(mandorApiClientProvider);
      final entries = await client.browseDirectory(widget.projectId, node.path);
      setState(() {
        node.children = entries.map((e) => _TreeNode(
          name: e.name,
          path: '${node.path}/${e.name}',
          isDirectory: e.isDirectory,
        )).toList();
        node.isExpanded = true;
        node.isLoading = false;
      });
    } catch (e) {
      setState(() {
        node.isLoading = false;
        node.children = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        if (isTablet) {
          return _buildTabletLayout(theme);
        }
        return _buildMobileLayout(theme);
      },
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final entriesAsync = ref.watch(
      browseProvider(BrowseParams(projectId: widget.projectId, path: _currentPath)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServerSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBreadcrumbBar(theme),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading files...'),
              error: (error, stack) => MandorErrorWidget(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.refresh(
                  browseProvider(BrowseParams(projectId: widget.projectId, path: _currentPath)),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Empty directory',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(
                      browseProvider(BrowseParams(projectId: widget.projectId, path: _currentPath)),
                    );
                    return Future.value();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length + (_currentPath.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_currentPath.isNotEmpty && index == 0) {
                        return _buildParentDirTile(theme);
                      }
                      final entryIndex = _currentPath.isNotEmpty ? index - 1 : index;
                      return _buildEntryTile(entries[entryIndex], theme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    if (_treeRoots.isEmpty) {
      _reloadTree();
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.projectName),
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showServerSettings(context),
            ),
          ],
        ),
        body: const LoadingIndicator(message: 'Loading files...'),
      );
    }

    final flatNodes = _flattenTree();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServerSettings(context),
          ),
        ],
      ),
      body: flatNodes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empty directory',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _onTreeRefresh();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: flatNodes.length,
                itemBuilder: (context, index) {
                  return _buildTreeTile(flatNodes[index], theme);
                },
              ),
            ),
    );
  }

  Widget _buildTreeTile(_FlatNode flatNode, ThemeData theme) {
    final node = flatNode.node;
    final depth = flatNode.depth;
    final isDir = node.isDirectory;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 8.0 + depth * 20, right: 8),
      leading: _treeLeading(node, isDir, theme),
      title: Text(
        node.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isDir
          ? Icon(
              node.isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: () => _toggleTreeNode(node),
    );
  }

  Widget _treeLeading(_TreeNode node, bool isDir, ThemeData theme) {
    if (node.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }
    return Icon(
      isDir ? Icons.folder : _getFileIcon(node.name),
      size: 20,
      color: isDir
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildBreadcrumbBar(ThemeData theme) {
    final parts = _currentPath.isEmpty ? <String>[] : _currentPath.split('/');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: theme.colorScheme.surfaceContainer,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBreadcrumbChip(0, '/', theme),
            for (int i = 0; i < parts.length; i++) ...[
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _buildBreadcrumbChip(i + 1, parts[i], theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbChip(int index, String label, ThemeData theme) {
    final isLast = index == (_currentPath.isEmpty ? 0 : _currentPath.split('/').length);
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: isLast
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: isLast ? null : () => _navigateToBreadcrumb(index),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildParentDirTile(ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.arrow_upward,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        '..',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: _navigateUp,
    );
  }

  Widget _buildEntryTile(FsEntry entry, ThemeData theme) {
    final isDir = entry.isDirectory;
    return ListTile(
      leading: Icon(
        isDir ? Icons.folder : _getFileIcon(entry.name),
        color: isDir
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        entry.name,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: isDir
          ? Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: () {
        if (isDir) {
          final newPath = _currentPath.isEmpty
              ? entry.name
              : '$_currentPath/${entry.name}';
          _navigateTo(newPath);
        } else {
          final filePath = _currentPath.isEmpty
              ? entry.name
              : '$_currentPath/${entry.name}';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileViewerScreen(
                projectId: widget.projectId,
                projectName: widget.projectName,
                filePath: filePath,
              ),
            ),
          );
        }
      },
    );
  }

  IconData _getFileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'ts':
      case 'tsx':
      case 'js':
      case 'jsx':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
      case 'toml':
        return Icons.tune;
      case 'md':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showServerSettings(BuildContext context) {
    final currentUrl = ref.read(mandorBaseUrlProvider);
    final currentToken = ref.read(mandorAuthTokenProvider);
    final urlController = TextEditingController(text: currentUrl);
    final tokenController = TextEditingController(text: currentToken ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://localhost:3000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token',
                hintText: 'Bearer token (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mandorBaseUrlProvider.notifier).state = urlController.text;
              ref.read(mandorAuthTokenProvider.notifier).state =
                  tokenController.text.isEmpty ? null : tokenController.text;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
