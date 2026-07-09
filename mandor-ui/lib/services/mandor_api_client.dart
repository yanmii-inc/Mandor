import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class MandorApiException implements Exception {
  final String message;
  final int? statusCode;
  final StackTrace? stackTrace;

  MandorApiException(this.message, [this.statusCode, this.stackTrace]);

  @override
  String toString() =>
      'MandorApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[MandorApi] $message');
  }
}

class MandorApiClient {
  final String baseUrl;
  String? authToken;
  late final http.Client _client;

  MandorApiClient({required this.baseUrl, this.authToken}) {
    _client = http.Client();
  }

  Map<String, String> get _authHeaders =>
      authToken != null ? {'Authorization': 'Bearer $authToken'} : const {};

  Future<List<Project>> getProjects() async {
    try {
      _log('Fetching projects from $baseUrl/projects');
      final response = await _client.get(
        Uri.parse('$baseUrl/projects'),
      );

      _log('Response status: ${response.statusCode}');
      _log('Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch projects: ${response.body}',
          response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      _log('Decoded JSON type: ${decoded.runtimeType}');
      
      // API returns array directly
      final List<dynamic> data = decoded is List ? decoded : (decoded['projects'] ?? []);
      _log('Parsing ${data.length} projects');
      
      final projects = <Project>[];
      for (int i = 0; i < data.length; i++) {
        try {
          _log('Parsing project $i...');
          final projectData = data[i] as Map<String, dynamic>;
          _log('Project $i raw data: $projectData');
          final project = Project.fromJson(projectData);
          _log('Successfully parsed project $i: ${project.name}');
          projects.add(project);
        } catch (e, st) {
          _log('ERROR parsing project $i: $e');
          _log('Stack trace: $st');
          rethrow;
        }
      }
      
      _log('Successfully loaded ${projects.length} projects');
      return projects;
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getProjects: $e');
      _log('Stack trace: $st');
      throw MandorApiException('Error fetching projects: $e', null, st);
    }
  }

  Future<Project> getProject(String projectId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/projects/$projectId'),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch project: ${response.body}',
          response.statusCode,
        );
      }

      return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error fetching project: $e');
    }
  }

  Future<Task> createTask(CreateTaskRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 201) {
        throw MandorApiException(
          'Failed to create task: ${response.body}',
          response.statusCode,
        );
      }

      return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error creating task: $e');
    }
  }

  Future<Task> getTask(String taskId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch task: ${response.body}',
          response.statusCode,
        );
      }

      return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error fetching task: $e');
    }
  }

  Future<List<Task>> getTasks({String? projectId}) async {
    try {
      _log('Fetching tasks${projectId != null ? ' for project $projectId' : ''}');
      final uri = Uri.parse('$baseUrl/tasks').replace(
        queryParameters: {
          'project_id': ?projectId,
        },
      );

      final response = await _client.get(uri);

      _log('Response status: ${response.statusCode}');
      _log('Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch tasks: ${response.body}',
          response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      _log('Decoded JSON type: ${decoded.runtimeType}');
      
      // API returns array directly or wrapped in 'tasks'
      final List<dynamic> data = decoded is List ? decoded : (decoded['tasks'] ?? []);
      _log('Parsing ${data.length} tasks');
      
      final tasks = <Task>[];
      for (int i = 0; i < data.length; i++) {
        try {
          _log('Parsing task $i...');
          final taskData = data[i] as Map<String, dynamic>;
          _log('Task $i raw data: $taskData');
          final task = Task.fromJson(taskData);
          _log('Successfully parsed task $i: ${task.id}');
          tasks.add(task);
        } catch (e, st) {
          _log('ERROR parsing task $i: $e');
          _log('Stack trace: $st');
          rethrow;
        }
      }
      
      _log('Successfully loaded ${tasks.length} tasks');
      return tasks;
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getTasks: $e');
      _log('Stack trace: $st');
      throw MandorApiException('Error fetching tasks: $e', null, st);
    }
  }

  Future<void> confirmTask(String taskId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/tasks/$taskId/confirm'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to confirm task: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error confirming task: $e');
    }
  }

  Future<void> replyToTask(String taskId, String message) async {
    try {
      final request = TaskReplyRequest(message: message);
      final response = await _client.post(
        Uri.parse('$baseUrl/tasks/$taskId/reply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to reply to task: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error replying to task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to delete task: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error deleting task: $e');
    }
  }

  /// Stream task logs using Server-Sent Events
  Stream<TaskLog> streamTaskLogs(String taskId) async* {
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/tasks/$taskId/logs'),
      );
      request.headers['Accept'] = 'text/event-stream';

      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to stream task logs: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        if (line.startsWith(':')) continue; // Skip comments

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;

          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield TaskLog.fromJson(data);
          } catch (e) {
            // Skip malformed JSON
            continue;
          }
        }
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error streaming task logs: $e');
    }
  }

  // ── Threads ───────────────────────────────────────────────────────

  Future<List<Thread>> getThreads({String? projectId}) async {
    try {
      _log('Fetching threads${projectId != null ? ' for project $projectId' : ''}');
      final uri = Uri.parse('$baseUrl/threads').replace(
        queryParameters: {
          'project_id': ?projectId,
        },
      );

      final response = await _client.get(uri);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch threads: ${response.body}',
          response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is List ? decoded : (decoded['threads'] ?? []);
      _log('Parsing ${data.length} threads');

      final threads = <Thread>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final threadData = data[i] as Map<String, dynamic>;
          threads.add(Thread.fromJson(threadData));
        } catch (e, st) {
          _log('ERROR parsing thread $i: $e');
          _log('Stack trace: $st');
          rethrow;
        }
      }

      _log('Successfully loaded ${threads.length} threads');
      return threads;
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getThreads: $e');
      _log('Stack trace: $st');
      throw MandorApiException('Error fetching threads: $e', null, st);
    }
  }

  Future<Thread> getThread(String threadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/threads/$threadId'),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch thread: ${response.body}',
          response.statusCode,
        );
      }

      return Thread.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error fetching thread: $e');
    }
  }

  Future<Thread> createThread(CreateThreadRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/threads'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 201) {
        throw MandorApiException(
          'Failed to create thread: ${response.body}',
          response.statusCode,
        );
      }

      return Thread.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error creating thread: $e');
    }
  }

  Future<void> replyToThread(String threadId, String message) async {
    try {
      final request = ThreadReplyRequest(message: message);
      final response = await _client.post(
        Uri.parse('$baseUrl/threads/$threadId/reply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 202) {
        throw MandorApiException(
          'Failed to reply to thread: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error replying to thread: $e');
    }
  }

  Future<void> deleteThread(String threadId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/threads/$threadId'),
      );

      if (response.statusCode != 204) {
        throw MandorApiException(
          'Failed to delete thread: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MandorApiException) rethrow;
      throw MandorApiException('Error deleting thread: $e');
    }
  }

  /// Stream thread logs using Server-Sent Events, auto-reconnecting
  /// when the connection is dropped.
  Stream<ThreadEvent> streamThreadLogs(String threadId) async* {
    // Track last reconnect to avoid tight loops
    var retryDelay = 500;

    while (true) {
      try {
        final request = http.Request(
          'GET',
          Uri.parse('$baseUrl/threads/$threadId/logs'),
        );
        request.headers['Accept'] = 'text/event-stream';

        final response = await _client.send(request);

        if (response.statusCode != 200) {
          throw MandorApiException(
            'Failed to stream thread logs: HTTP ${response.statusCode}',
            response.statusCode,
          );
        }

        // Reset retry delay on successful connection
        retryDelay = 500;

        String currentEvent = '';
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.isEmpty) continue;
          if (line.startsWith(':')) continue;

          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
            continue;
          }

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              yield ThreadEvent(
                event: currentEvent.isNotEmpty ? currentEvent : null,
                role: data['role'] as String?,
                chunk: data['chunk'] as String?,
                type: data['type'] as String?,
                content: data['content'] as String?,
                errorMessage: data['message'] as String?,
                timestamp: data['timestamp'] != null
                    ? DateTime.parse(data['timestamp'] as String)
                    : null,
              );
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        if (e is MandorApiException) rethrow;
        throw MandorApiException('Error streaming thread logs: $e');
      }

      // Stream ended — wait before reconnecting
      await Future.delayed(Duration(milliseconds: retryDelay));
      retryDelay = (retryDelay * 2).clamp(500, 10_000);
    }
  }

  // ── File Browser ───────────────────────────────────────────────────

  Future<List<FsEntry>> browseDirectory(String projectId, String path, {int offset = 0, int? limit}) async {
    try {
      final safePath = path.isEmpty ? '.' : path;
      _log('Browsing directory: project=$projectId path=$safePath auth=${authToken != null ? 'yes' : 'no'}');
      final params = <String, String>{
        'path': safePath,
        'offset': offset.toString(),
      };
      if (limit != null) params['limit'] = limit.toString();

      final response = await _client.get(
        Uri.parse('$baseUrl/browse/$projectId').replace(queryParameters: params),
        headers: _authHeaders,
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to browse directory: ${response.body}',
          response.statusCode,
        );
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => FsEntry.fromJson(e as Map<String, dynamic>)).toList();
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in browseDirectory: $e');
      throw MandorApiException('Error browsing directory: $e', null, st);
    }
  }

  Future<FileMetadata> getFileMetadata(String projectId, String path) async {
    try {
      _log('Fetching file metadata: project=$projectId path=$path');
      final response = await _client.get(
        Uri.parse('$baseUrl/file/$projectId').replace(queryParameters: {'path': path}),
        headers: _authHeaders,
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch file metadata: ${response.body}',
          response.statusCode,
        );
      }

      return FileMetadata.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getFileMetadata: $e');
      throw MandorApiException('Error fetching file metadata: $e', null, st);
    }
  }

  Future<String> getFileContent(String projectId, String path) async {
    try {
      _log('Fetching file content: project=$projectId path=$path');
      final response = await _client.get(
        Uri.parse('$baseUrl/file/$projectId/content').replace(queryParameters: {'path': path}),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      if (response.statusCode == 416) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw MandorApiException(
          error['error'] as String? ?? 'File too large or binary',
          response.statusCode,
        );
      }

      throw MandorApiException(
        'Failed to fetch file content: ${response.body}',
        response.statusCode,
      );
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getFileContent: $e');
      throw MandorApiException('Error fetching file content: $e', null, st);
    }
  }

  // ── Models ──────────────────────────────────────────────────────

  Future<Map<String, List<ModelInfo>>> getModels() async {
    try {
      _log('Fetching models from $baseUrl/models');
      final response = await _client.get(
        Uri.parse('$baseUrl/models'),
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch models: ${response.body}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = <String, List<ModelInfo>>{};
      data.forEach((provider, models) {
        final list = (models as List<dynamic>)
            .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        result[provider] = list;
      });
      return result;
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getModels: $e');
      throw MandorApiException('Error fetching models: $e', null, st);
    }
  }

  // ── Agent Profiles ────────────────────────────────────────────────

  Future<List<AgentProfile>> getAgentProfiles() async {
    try {
      _log('Fetching agent profiles from $baseUrl/agent-profiles');
      final response = await _client.get(
        Uri.parse('$baseUrl/agent-profiles'),
        headers: _authHeaders,
      );

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch agent profiles: ${response.body}',
          response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((e) => AgentProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getAgentProfiles: $e');
      throw MandorApiException('Error fetching agent profiles: $e', null, st);
    }
  }

  /// Discover the models an agent profile supports. Set [refresh] to bypass the
  /// server's cache. Returns a [ProfileModels] whose `freeForm` is true when the
  /// agent exposes no list (CLI agents) — the caller then renders a text field.
  Future<ProfileModels> getProfileModels(String profileId,
      {bool refresh = false}) async {
    try {
      _log('Fetching models for profile $profileId');
      final uri = Uri.parse('$baseUrl/agent-profiles/$profileId/models')
          .replace(queryParameters: refresh ? const {'refresh': 'true'} : null);
      final response = await _client.get(uri, headers: _authHeaders);

      if (response.statusCode != 200) {
        throw MandorApiException(
          'Failed to fetch profile models: ${response.body}',
          response.statusCode,
        );
      }

      return ProfileModels.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on MandorApiException {
      rethrow;
    } catch (e, st) {
      _log('ERROR in getProfileModels: $e');
      throw MandorApiException('Error fetching profile models: $e', null, st);
    }
  }

  void close() {
    _client.close();
  }
}
