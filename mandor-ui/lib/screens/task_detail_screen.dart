import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../widgets/mandor_widgets.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(taskLogsStreamProvider(task.id ?? 'unknown'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Task info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.description ?? 'Unknown task',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TaskStatusIndicator(status: task.status ?? 'unknown'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (task.complexity != null)
                      Chip(label: Text('Complexity: ${task.complexity}')),
                    if (task.tokenUsage != null)
                      Chip(
                        label: Text('Tokens: ${task.tokenUsage!.total}'),
                        avatar: const Icon(Icons.token, size: 16),
                      ),
                    if (task.prUrl != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          // Would open PR in browser
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View PR'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Task logs
          Expanded(
            child: logsAsync.when(
              loading: () => const LoadingIndicator(message: 'Connecting to task...'),
              error: (error, stack) => MandorErrorWidget(
                error: error,
                stackTrace: stack,
              ),
              data: (log) {
                // Note: This shows one log at a time from the stream
                // In a full implementation, you'd accumulate logs in state
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: TaskLogItem(log: log),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
