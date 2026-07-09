import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../providers/model_selection_provider.dart';
import '../widgets/mandor_widgets.dart';
import 'file_browser_screen.dart';
import 'project_info_screen.dart';
import 'task_detail_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider(project.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name ?? 'Project'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Task',
            onPressed: () => _showCreateTaskDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.forum),
            tooltip: 'New Thread',
            onPressed: () => _showCreateThreadDialog(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'project_info':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectInfoScreen(project: project),
                    ),
                  );
                case 'browse_files':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileBrowserScreen(
                        projectId: project.id ?? '',
                        projectName: project.name ?? 'Project',
                      ),
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'project_info',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Project Info'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'browse_files',
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Browse Files'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tasks list
          Expanded(
            child: tasksAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading tasks...'),
              error: (error, stack) => MandorErrorWidget(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.refresh(tasksProvider(project.id)),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dispatch your first task to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: tasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TaskCard(
                              task: task,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Thread'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                validator: (val) =>
                    val == null || val.trim().isEmpty
                        ? 'Message is required'
                        : null,
              ),
            ],
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
                Navigator.pop(dialogContext);
                final pid = project.id!;
                ref
                    .read(threadCreationProvider.notifier)
                    .createThread(pid, message, title: title)
                    .then((_) {
                  ref
                    ..invalidate(threadsProvider(pid))
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
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe the task for the AI agent',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          minLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: project.id != null
                ? () {
                    // Apply the agent + model chosen in the switcher (if any).
                    final selection = ref.read(modelSelectionProvider);
                    ref.read(taskCreationProvider.notifier).createTask(
                          project.id!,
                          controller.text,
                          agentProfileId: selection.agentProfileId,
                          model: selection.modelId,
                        );
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
