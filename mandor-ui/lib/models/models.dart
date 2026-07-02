import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

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
  final String projectId;
  final String description;
  final String? model;

  CreateTaskRequest({
    required this.projectId,
    required this.description,
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
  final String? projectId;
  final String? agentProfileId;
  final String? title;
  final String? sessionId;
  final String? model;
  final TokenUsage? tokenUsage;
  final DateTime? createdAt;
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
  final String projectId;
  final String message;
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
