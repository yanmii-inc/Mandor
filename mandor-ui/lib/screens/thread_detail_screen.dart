import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/mandor_providers.dart';
import '../providers/model_selection_provider.dart';
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
  String? _selectedModelId;

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

  String? _findModelLabel(List<ModelInfo> models, String? modelId) {
    if (modelId == null) return null;
    for (final m in models) {
      if (m.id == modelId) return m.label;
    }
    return modelId;
  }

  void _showModelPicker(BuildContext context, ProfileModels pm) {
    final currentId = _selectedModelId ?? widget.thread.model;

    // CLI/free-form agents expose no model list — just show the active model.
    if (pm.freeForm || pm.models.isEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Current model: ${currentId ?? "(agent default)"}\n\n'
            'This agent does not expose a model list.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Model',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final model in pm.models)
                  ListTile(
                    leading: Icon(
                      model.id == currentId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: model.id == currentId
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(model.label),
                    subtitle: Text(
                      model.id,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      setState(() => _selectedModelId = model.id);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
                Consumer(
                  builder: (context, ref, _) {
                    final pmAsync = ref.watch(profileModelsProvider(
                        widget.thread.agentProfileId ?? ''));
                    return pmAsync.when(
                      data: (pm) {
                        final modelId = _selectedModelId ?? widget.thread.model;
                        final label = _findModelLabel(pm.models, modelId);
                        return ActionChip(
                          avatar: const Icon(Icons.smart_toy_outlined, size: 16),
                          label: Text(
                            label ?? 'Model',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _showModelPicker(context, pm),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
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

    _events.add(ThreadEvent(
      event: 'log',
      role: 'user',
      chunk: text,
    ));
    _scrollToBottom();

    ref
        .read(threadActionProvider.notifier)
        .replyToThread(widget.thread.id ?? '', text)
        .then((_) {
          if (mounted) setState(() => _isSending = false);
        })
        .catchError((e) {
          if (mounted) {
            setState(() => _isSending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: $e'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
  }
}
