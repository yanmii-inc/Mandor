import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name ?? 'Unknown Project',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                project.repoUrl ?? 'No URL',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (project.agentProfileId != null)
                    Chip(
                      label: Text(project.agentProfileId!.substring(0, 8)),
                      avatar: const Icon(Icons.smart_toy, size: 16),
                    ),
                  if (project.source != null)
                    Chip(
                      label: Text(project.source!),
                    ),
                  if (project.createdAt != null)
                    Text(
                      timeago.format(project.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.blue;
      case 'pr_ready':
        return Colors.green;
      case 'merged':
        return Colors.teal;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'running':
        return Icons.hourglass_bottom;
      case 'pr_ready':
        return Icons.check_circle;
      case 'merged':
        return Icons.merge_type;
      case 'failed':
        return Icons.error;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status ?? 'unknown');
    final statusIcon = _getStatusIcon(task.status ?? 'unknown');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.description ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    avatar: Icon(statusIcon, size: 16),
                    label: Text((task.status ?? 'unknown').replaceAll('_', ' ')),
                    backgroundColor: statusColor.withAlpha((0.2 * 255).toInt()),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.complexity != null)
                    Chip(
                      label: Text(
                        task.complexity!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (task.tokenUsage != null)
                    Chip(
                      label: Text(
                        '${task.tokenUsage!.total} tokens',
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: const Icon(Icons.token, size: 16),
                    ),
                  if (task.createdAt != null)
                    Text(
                      timeago.format(task.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              if (task.prUrl != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Would open PR in browser
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View PR'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ThreadCard extends StatelessWidget {
  final Thread thread;
  final VoidCallback onTap;

  const ThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSession = thread.sessionId != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      thread.title ?? 'Untitled',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      hasSession ? Icons.chat : Icons.chat_bubble_outline,
                      size: 16,
                    ),
                    label: Text(hasSession ? 'Active' : 'New'),
                    backgroundColor: hasSession
                        ? Colors.green.withAlpha((0.15 * 255).toInt())
                        : Colors.blue.withAlpha((0.15 * 255).toInt()),
                    labelStyle: TextStyle(
                      color: hasSession ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (thread.projectId != null)
                    Text(
                      'Project: ${thread.projectId!.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (thread.createdAt != null)
                    Text(
                      timeago.format(thread.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskLogItem extends StatelessWidget {
  final TaskLog log;
  final bool isLast;

  const TaskLogItem({
    super.key,
    required this.log,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUserMessage = log.role == 'user';
    final bgColor = isUserMessage
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainer;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            SelectableText(
              log.chunk ?? '(empty message)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            if (log.timestamp != null)
              Text(
                timeago.format(log.timestamp!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class TaskStatusIndicator extends StatelessWidget {
  final String status;

  const TaskStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'running':
        color = Colors.blue;
        icon = Icons.hourglass_bottom;
        label = 'Running';
      case 'pr_ready':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'PR Ready';
      case 'merged':
        color = Colors.teal;
        icon = Icons.merge_type;
        label = 'Merged';
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        label = 'Failed';
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        label = 'Pending';
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = status;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withAlpha((0.15 * 255).toInt()),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class MandorErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const MandorErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (stackTrace != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          stackTrace.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
