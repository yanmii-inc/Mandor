import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../widgets/mandor_widgets.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
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
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mandor Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mandorBaseUrlProvider.notifier).state = controller.text;
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

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(projectsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServerSettings(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading projects...'),
        error: (error, stack) => MandorErrorWidget(
          error: error,
          stackTrace: stack,
          onRetry: () => ref.refresh(projectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create or scan for projects to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final crossAxisCount = isMobile ? 1 : (constraints.maxWidth < 1024 ? 2 : 3);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return ProjectCard(
                      project: projects[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            project: projects[index],
                          ),
                        ),
                      ),
                    );
                  },
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
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mandor Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mandorBaseUrlProvider.notifier).state = controller.text;
              // ignore: unused_result
              ref.refresh(projectsProvider);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

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
      ),
      body: Column(
        children: [
          // Project info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repository',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  project.repoUrl ?? 'No URL configured',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Local Path',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  project.localPath ?? 'No path configured',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Create task / thread buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showCreateTaskDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('New Task'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCreateThreadDialog(context, ref),
                    icon: const Icon(Icons.forum),
                    label: const Text('New Thread'),
                  ),
                ),
              ],
            ),
          ),
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
                ref.read(threadCreationProvider.notifier).createThread(
                      project.id!,
                      messageController.text,
                      title: titleController.text.isNotEmpty
                          ? titleController.text
                          : null,
                    );
                Navigator.pop(dialogContext);
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
                    ref.read(taskCreationProvider.notifier).createTask(
                          project.id!,
                          controller.text,
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

class ThreadsListScreen extends ConsumerWidget {
  const ThreadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Threads'),
        actions: [
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
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mandor Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:3000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mandorBaseUrlProvider.notifier).state = controller.text;
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
                  if (true) ...[
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
                  ref
                      .read(threadCreationProvider.notifier)
                      .createThread(
                        selectedProjectId!,
                        messageController.text,
                        title: titleController.text.isNotEmpty
                            ? titleController.text
                            : null,
                      );
                  Navigator.pop(dialogContext);
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

class ThreadDetailScreen extends ConsumerStatefulWidget {
  final Thread thread;

  const ThreadDetailScreen({super.key, required this.thread});

  @override
  ConsumerState<ThreadDetailScreen> createState() =>
      _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final List<ThreadEvent> _events = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ThreadEvent>>(
      threadLogsStreamProvider(widget.thread.id ?? ''),
      (prev, next) {
        next.whenData((event) {
          setState(() => _events.add(event));
          _scrollToBottom();
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.title ?? 'Thread'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _events.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Thread info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.thread.sessionId != null)
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Active'),
                    backgroundColor: Colors.green.withAlpha((0.15 * 255).toInt()),
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                else
                  Chip(
                    avatar: const Icon(Icons.hourglass_empty, size: 16),
                    label: const Text('Pending'),
                    backgroundColor: Colors.orange.withAlpha((0.15 * 255).toInt()),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (widget.thread.createdAt != null)
                  Chip(
                    label: Text(
                      timeago.format(widget.thread.createdAt!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Messages area
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _buildEventWidget(event, context);
                    },
                  ),
          ),
          // Reply input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isSending ? null : (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventWidget(ThreadEvent event, BuildContext context) {
    final isLog = event.event == 'log';
    final isMessage = event.event == 'message';
    final isError = event.event == 'error';

    if (isError && event.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withAlpha((0.3 * 255).toInt())),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLog && event.role != null) {
      final isUser = event.role == 'user';
      final bgColor = isUser
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainer;

      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SelectableText(
                event.chunk ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (event.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  timeago.format(event.timestamp!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isMessage && event.content != null && event.type == 'text') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                event.content!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (event.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  timeago.format(event.timestamp!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (event.event == 'done') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Turn completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    ref.read(threadActionProvider.notifier).replyToThread(
          widget.thread.id ?? '',
          text,
        );

    // Add a local user event immediately for instant feedback
    setState(() {
      _events.add(ThreadEvent(
        event: 'log',
        role: 'user',
        chunk: text,
      ));
      _isSending = false;
    });
    _scrollToBottom();
  }
}

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
