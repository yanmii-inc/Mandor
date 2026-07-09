import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

TokenUsage? _parseTokenUsage(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) {
    return TokenUsage.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
  return TokenUsage.fromJson(value as Map<String, dynamic>);
}

dynamic _tokenUsageToJson(TokenUsage? usage) => usage?.toJson();

@JsonSerializable()
class Project {
  final String? id;
  final String? name;
  final String? repoUrl;
  final String? localPath;
  final String? agentProfileId;
  final String? source;
  final List<DeployTarget>? targets;
  final DateTime? createdAt;

  Project({
    this.id,
    this.name,
    this.repoUrl,
    this.localPath,
    this.agentProfileId,
    this.source,
    this.targets,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable()
class DeployTarget {
  final String? name;
  final String? path;
  final String? deployCommand;

  DeployTarget({
    this.name,
    this.path,
    this.deployCommand,
  });

  factory DeployTarget.fromJson(Map<String, dynamic> json) =>
      _$DeployTargetFromJson(json);
  Map<String, dynamic> toJson() => _$DeployTargetToJson(this);
}

@JsonSerializable()
class Task {
  final String? id;
  final String? projectId;
  final String? agentProfileId;
  final String? description;
  final String? status; // pending, running, pr_ready, merged, failed
  final String? worktreePath;
  final String? branchName;
  final String? prUrl;
  final String? sessionId;
  final String? complexity; // simple, medium, complex
  final TokenUsage? tokenUsage;
  final bool? confirmed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    this.projectId,
    this.agentProfileId,
    this.description,
    this.status,
    this.worktreePath,
    this.branchName,
    this.prUrl,
    this.sessionId,
    this.complexity,
    this.tokenUsage,
    this.confirmed,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  bool get isRunning => status == 'running' || status == 'pending';
  bool get isCompleted =>
      status == 'pr_ready' || status == 'merged' || status == 'failed';
}

@JsonSerializable()
class TokenUsage {
  final int? inputTokens;
  final int? outputTokens;

  TokenUsage({
    this.inputTokens,
    this.outputTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageFromJson(json);
  Map<String, dynamic> toJson() => _$TokenUsageToJson(this);

  int get total => (inputTokens ?? 0) + (outputTokens ?? 0);
}

@JsonSerializable()
class TaskLog {
  final String? id;
  final String? taskId;
  final String? role; // 'user' or 'agent'
  final String? chunk;
  final DateTime? timestamp;

  TaskLog({
    this.id,
    this.taskId,
    this.role,
    this.chunk,
    this.timestamp,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) =>
      _$TaskLogFromJson(json);
  Map<String, dynamic> toJson() => _$TaskLogToJson(this);
}

@JsonSerializable()
class AgentProfile {
  final String? id;
  final String? name;
  final String? agentType;
  final DateTime? createdAt;

  AgentProfile({
    this.id,
    this.name,
    this.agentType,
    this.createdAt,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> json) =>
      _$AgentProfileFromJson(json);
  Map<String, dynamic> toJson() => _$AgentProfileToJson(this);
}

@JsonSerializable()
class CreateTaskRequest {
  @JsonKey(name: 'project_id')
  final String projectId;
  final String description;
  @JsonKey(name: 'agent_profile_id')
  final String? agentProfileId;
  final String? model;

  CreateTaskRequest({
    required this.projectId,
    required this.description,
    this.agentProfileId,
    this.model,
  });

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

@JsonSerializable()
class TaskReplyRequest {
  final String message;

  TaskReplyRequest({required this.message});

  factory TaskReplyRequest.fromJson(Map<String, dynamic> json) =>
      _$TaskReplyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TaskReplyRequestToJson(this);
}

@JsonSerializable()
class Thread {
  final String? id;

  @JsonKey(name: 'project_id')
  final String? projectId;

  @JsonKey(name: 'agent_profile_id')
  final String? agentProfileId;

  final String? title;

  @JsonKey(name: 'session_id')
  final String? sessionId;

  final String? model;

  @JsonKey(
    name: 'token_usage',
    fromJson: _parseTokenUsage,
    toJson: _tokenUsageToJson,
  )
  final TokenUsage? tokenUsage;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Thread({
    this.id,
    this.projectId,
    this.agentProfileId,
    this.title,
    this.sessionId,
    this.model,
    this.tokenUsage,
    this.createdAt,
    this.updatedAt,
  });

  factory Thread.fromJson(Map<String, dynamic> json) =>
      _$ThreadFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadToJson(this);
}

@JsonSerializable()
class CreateThreadRequest {
  @JsonKey(name: 'project_id')
  final String projectId;

  final String message;

  @JsonKey(name: 'agent_profile_id')
  final String? agentProfileId;

  final String? title;
  final String? model;

  CreateThreadRequest({
    required this.projectId,
    required this.message,
    this.agentProfileId,
    this.title,
    this.model,
  });

  factory CreateThreadRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateThreadRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateThreadRequestToJson(this);
}

@JsonSerializable()
class ThreadReplyRequest {
  final String message;

  ThreadReplyRequest({required this.message});

  factory ThreadReplyRequest.fromJson(Map<String, dynamic> json) =>
      _$ThreadReplyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadReplyRequestToJson(this);
}

class FsEntry {
  final String name;
  final String type;

  FsEntry({required this.name, required this.type});

  factory FsEntry.fromJson(Map<String, dynamic> json) {
    return FsEntry(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'type': type};

  bool get isDirectory => type == 'directory';
}

class FileMetadata {
  final int size;
  final String mime;
  final DateTime modifiedAt;
  final int? lineCount;

  FileMetadata({
    required this.size,
    required this.mime,
    required this.modifiedAt,
    this.lineCount,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      size: json['size'] as int,
      mime: json['mime'] as String,
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      lineCount: json['lineCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'size': size,
    'mime': mime,
    'modifiedAt': modifiedAt.toIso8601String(),
    'lineCount': lineCount,
  };

  bool get isText =>
      lineCount != null ||
      mime.startsWith('text/') ||
      _codeMimes.contains(mime);
}

const _codeMimes = {
  'application/json',
  'application/typescript',
  'application/javascript',
  'application/xml',
  'application/yaml',
  'application/x-sh',
  'application/x-bash',
};

class ModelInfo {
  final String id;
  final String label;

  const ModelInfo({required this.id, required this.label});

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

/// Models an agent profile can use, discovered live from the agent.
/// When [freeForm] is true the agent exposes no list (CLI agents) and the user
/// types the model string freehand.
class ProfileModels {
  final List<ModelInfo> models;
  final bool freeForm;

  const ProfileModels({required this.models, required this.freeForm});

  factory ProfileModels.fromJson(Map<String, dynamic> json) {
    final list = (json['models'] as List<dynamic>? ?? [])
        .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProfileModels(
      models: list,
      freeForm: (json['freeForm'] as bool?) ?? list.isEmpty,
    );
  }
}

class ThreadEvent {
  final String? event;
  final String? role;
  final String? chunk;
  final String? type;
  final String? content;
  final String? errorMessage;
  final DateTime? timestamp;

  ThreadEvent({
    this.event,
    this.role,
    this.chunk,
    this.type,
    this.content,
    this.errorMessage,
    this.timestamp,
  });
}
