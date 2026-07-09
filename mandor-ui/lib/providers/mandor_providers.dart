import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/mandor_api_client.dart';

// Configuration providers
final mandorBaseUrlProvider = StateProvider<String>((ref) {
  return 'http://localhost:3000';
});

final mandorAuthTokenProvider = StateProvider<String?>((ref) => null);

// API client provider
final mandorApiClientProvider = Provider((ref) {
  final baseUrl = ref.watch(mandorBaseUrlProvider);
  final authToken = ref.watch(mandorAuthTokenProvider);
  return MandorApiClient(baseUrl: baseUrl, authToken: authToken);
});

// Projects provider
final projectsProvider = FutureProvider((ref) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getProjects();
});

// Single project provider
final projectProvider = FutureProvider.family<Project, String>((ref, projectId) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getProject(projectId);
});

// Tasks provider with optional filter
final tasksProvider = FutureProvider.family<List<Task>, String?>((ref, projectId) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getTasks(projectId: projectId);
});

// Single task provider
final taskProvider = FutureProvider.family<Task, String>((ref, taskId) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getTask(taskId);
});

// Task logs stream provider
final taskLogsStreamProvider = StreamProvider.family<TaskLog, String>((ref, taskId) {
  final client = ref.watch(mandorApiClientProvider);
  return client.streamTaskLogs(taskId);
});

// Notifier for task creation
class TaskCreationNotifier extends StateNotifier<AsyncValue<Task?>> {
  final MandorApiClient _client;

  TaskCreationNotifier(this._client) : super(const AsyncValue.data(null));

  Future<void> createTask(
    String projectId,
    String description, {
    String? agentProfileId,
    String? model,
  }) async {
    state = const AsyncValue.loading();
    try {
      final request = CreateTaskRequest(
        projectId: projectId,
        description: description,
        agentProfileId: agentProfileId,
        model: model,
      );
      final task = await _client.createTask(request);
      state = AsyncValue.data(task);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskCreationProvider =
    StateNotifierProvider<TaskCreationNotifier, AsyncValue<Task?>>((ref) {
  final client = ref.watch(mandorApiClientProvider);
  return TaskCreationNotifier(client);
});

// Notifier for task actions (confirm, reply, delete)
class TaskActionNotifier extends StateNotifier<AsyncValue<void>> {
  final MandorApiClient _client;

  TaskActionNotifier(this._client) : super(const AsyncValue.data(null));

  Future<void> confirmTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _client.confirmTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> replyToTask(String taskId, String message) async {
    state = const AsyncValue.loading();
    try {
      await _client.replyToTask(taskId, message);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _client.deleteTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskActionProvider =
    StateNotifierProvider<TaskActionNotifier, AsyncValue<void>>((ref) {
  final client = ref.watch(mandorApiClientProvider);
  return TaskActionNotifier(client);
});

// ── Thread Providers ─────────────────────────────────────────────────

final threadsProvider =
    FutureProvider.family<List<Thread>, String?>((ref, projectId) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getThreads(projectId: projectId);
});

final threadProvider =
    FutureProvider.family<Thread, String>((ref, threadId) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getThread(threadId);
});

final threadLogsStreamProvider =
    StreamProvider.family<ThreadEvent, String>((ref, threadId) {
  final client = ref.watch(mandorApiClientProvider);
  return client.streamThreadLogs(threadId);
});

class ThreadCreationNotifier extends StateNotifier<AsyncValue<Thread?>> {
  final MandorApiClient _client;

  ThreadCreationNotifier(this._client) : super(const AsyncValue.data(null));

  Future<void> createThread(String projectId, String message,
      {String? title, String? agentProfileId, String? model}) async {
    state = const AsyncValue.loading();
    try {
      final request = CreateThreadRequest(
        projectId: projectId,
        message: message,
        title: title,
        agentProfileId: agentProfileId,
        model: model,
      );
      final thread = await _client.createThread(request);
      state = AsyncValue.data(thread);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final threadCreationProvider = StateNotifierProvider<ThreadCreationNotifier,
    AsyncValue<Thread?>>((ref) {
  final client = ref.watch(mandorApiClientProvider);
  return ThreadCreationNotifier(client);
});

class ThreadActionNotifier extends StateNotifier<AsyncValue<void>> {
  final MandorApiClient _client;

  ThreadActionNotifier(this._client) : super(const AsyncValue.data(null));

  Future<void> replyToThread(String threadId, String message) async {
    state = const AsyncValue.loading();
    try {
      await _client.replyToThread(threadId, message);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteThread(String threadId) async {
    state = const AsyncValue.loading();
    try {
      await _client.deleteThread(threadId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final threadActionProvider =
    StateNotifierProvider<ThreadActionNotifier, AsyncValue<void>>((ref) {
  final client = ref.watch(mandorApiClientProvider);
  return ThreadActionNotifier(client);
});

// Model discovery + selection live in model_selection_provider.dart
// (per-agent-profile, discovered live from each agent).

// ── File Browser Providers ───────────────────────────────────────────

class BrowseParams {
  final String projectId;
  final String path;

  BrowseParams({required this.projectId, required this.path});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseParams &&
          projectId == other.projectId &&
          path == other.path;

  @override
  int get hashCode => projectId.hashCode ^ path.hashCode;
}

final browseProvider =
    FutureProvider.family<List<FsEntry>, BrowseParams>((ref, params) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.browseDirectory(params.projectId, params.path);
});

class FileParams {
  final String projectId;
  final String path;

  FileParams({required this.projectId, required this.path});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileParams &&
          projectId == other.projectId &&
          path == other.path;

  @override
  int get hashCode => projectId.hashCode ^ path.hashCode;
}

final fileMetadataProvider =
    FutureProvider.family<FileMetadata, FileParams>((ref, params) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getFileMetadata(params.projectId, params.path);
});

final fileContentProvider =
    FutureProvider.family<String, FileParams>((ref, params) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getFileContent(params.projectId, params.path);
});
