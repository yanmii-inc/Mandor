import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mandor_providers.dart';
import '../providers/model_selection_provider.dart';
import '../widgets/mandor_widgets.dart';
import '../widgets/model_switcher_widget.dart';
import 'thread_detail_screen.dart';

class ThreadsListScreen extends ConsumerWidget {
  const ThreadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Threads'),
        actions: [
          const ModelSwitcher(iconOnly: true),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(threadsProvider(null)),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServerSettings(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateThreadDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: threadsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading threads...'),
        error: (error, stack) => MandorErrorWidget(
          error: error,
          stackTrace: stack,
          onRetry: () => ref.refresh(threadsProvider(null)),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No threads yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with an AI agent',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(threadsProvider(null).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ThreadCard(
                    thread: threads[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ThreadDetailScreen(thread: threads[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showServerSettings(BuildContext context, WidgetRef ref) {
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
              // ignore: unused_result
              ref.refresh(threadsProvider(null));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateThreadDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedProjectId;

        return AlertDialog(
          title: const Text('New Thread'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref2, _) {
                      final projectsAsync = ref2.watch(projectsProvider);

                      return projectsAsync.when(
                        loading: () => const Text('Loading projects...'),
                        error: (e, _) => Text('Error loading projects: $e'),
                        data: (projects) {
                          if (projects.isEmpty) {
                            return Column(
                              children: [
                                Icon(
                                  Icons.folder_off,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No projects available',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create a project first before starting a thread',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }

                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Project',
                              border: OutlineInputBorder(),
                            ),
                            items: projects
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.name ?? 'Unknown'),
                                    ))
                                .toList(),
                            onChanged: (val) => selectedProjectId = val,
                            validator: (val) => val == null
                                ? 'Please select a project'
                                : null,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      hintText: 'Brief topic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Ask the agent something...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    minLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Message is required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final message = messageController.text;
                  final title = titleController.text.isNotEmpty
                      ? titleController.text
                      : null;
                  // Apply the agent + model chosen in the switcher (if any).
                  final selection = ref.read(modelSelectionProvider);

                  Navigator.pop(dialogContext);
                  final projectId = selectedProjectId!;
                  ref
                      .read(threadCreationProvider.notifier)
                      .createThread(
                        projectId,
                        message,
                        title: title,
                        agentProfileId: selection.agentProfileId,
                        model: selection.modelId,
                      )
                      .then((_) {
                    ref
                      ..invalidate(threadsProvider(projectId))
                      ..invalidate(threadsProvider(null));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thread created'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }).catchError((e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
