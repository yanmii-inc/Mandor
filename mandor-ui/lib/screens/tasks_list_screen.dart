import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mandor_providers.dart';
import '../widgets/mandor_widgets.dart';
import '../widgets/model_switcher_widget.dart';
import 'task_detail_screen.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const ModelSwitcher(iconOnly: true),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(tasksProvider(null)),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServerSettings(context, ref),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading tasks...'),
        error: (error, stack) => MandorErrorWidget(
          error: error,
          stackTrace: stack,
          onRetry: () => ref.refresh(tasksProvider(null)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasks dispatched to agents will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(tasksProvider(null).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: tasks[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: tasks[index]),
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
              ref.refresh(tasksProvider(null));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
