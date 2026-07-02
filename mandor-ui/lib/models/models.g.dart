// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String?,
  name: json['name'] as String?,
  repoUrl: json['repoUrl'] as String?,
  localPath: json['localPath'] as String?,
  agentProfileId: json['agentProfileId'] as String?,
  source: json['source'] as String?,
  targets: (json['targets'] as List<dynamic>?)
      ?.map((e) => DeployTarget.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'repoUrl': instance.repoUrl,
  'localPath': instance.localPath,
  'agentProfileId': instance.agentProfileId,
  'source': instance.source,
  'targets': instance.targets,
  'createdAt': instance.createdAt?.toIso8601String(),
};

DeployTarget _$DeployTargetFromJson(Map<String, dynamic> json) => DeployTarget(
  name: json['name'] as String?,
  path: json['path'] as String?,
  deployCommand: json['deployCommand'] as String?,
);

Map<String, dynamic> _$DeployTargetToJson(DeployTarget instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'deployCommand': instance.deployCommand,
    };

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String?,
  projectId: json['projectId'] as String?,
  agentProfileId: json['agentProfileId'] as String?,
  description: json['description'] as String?,
  status: json['status'] as String?,
  worktreePath: json['worktreePath'] as String?,
  branchName: json['branchName'] as String?,
  prUrl: json['prUrl'] as String?,
  sessionId: json['sessionId'] as String?,
  complexity: json['complexity'] as String?,
  tokenUsage: json['tokenUsage'] == null
      ? null
      : TokenUsage.fromJson(json['tokenUsage'] as Map<String, dynamic>),
  confirmed: json['confirmed'] as bool?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'agentProfileId': instance.agentProfileId,
  'description': instance.description,
  'status': instance.status,
  'worktreePath': instance.worktreePath,
  'branchName': instance.branchName,
  'prUrl': instance.prUrl,
  'sessionId': instance.sessionId,
  'complexity': instance.complexity,
  'tokenUsage': instance.tokenUsage,
  'confirmed': instance.confirmed,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

TokenUsage _$TokenUsageFromJson(Map<String, dynamic> json) => TokenUsage(
  inputTokens: (json['inputTokens'] as num?)?.toInt(),
  outputTokens: (json['outputTokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$TokenUsageToJson(TokenUsage instance) =>
    <String, dynamic>{
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
    };

TaskLog _$TaskLogFromJson(Map<String, dynamic> json) => TaskLog(
  id: json['id'] as String?,
  taskId: json['taskId'] as String?,
  role: json['role'] as String?,
  chunk: json['chunk'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$TaskLogToJson(TaskLog instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'role': instance.role,
  'chunk': instance.chunk,
  'timestamp': instance.timestamp?.toIso8601String(),
};

AgentProfile _$AgentProfileFromJson(Map<String, dynamic> json) => AgentProfile(
  id: json['id'] as String?,
  name: json['name'] as String?,
  agentType: json['agentType'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AgentProfileToJson(AgentProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'agentType': instance.agentType,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

CreateTaskRequest _$CreateTaskRequestFromJson(Map<String, dynamic> json) =>
    CreateTaskRequest(
      projectId: json['projectId'] as String,
      description: json['description'] as String,
      model: json['model'] as String?,
    );

Map<String, dynamic> _$CreateTaskRequestToJson(CreateTaskRequest instance) =>
    <String, dynamic>{
      'projectId': instance.projectId,
      'description': instance.description,
      'model': instance.model,
    };

TaskReplyRequest _$TaskReplyRequestFromJson(Map<String, dynamic> json) =>
    TaskReplyRequest(message: json['message'] as String);

Map<String, dynamic> _$TaskReplyRequestToJson(TaskReplyRequest instance) =>
    <String, dynamic>{'message': instance.message};

Thread _$ThreadFromJson(Map<String, dynamic> json) => Thread(
  id: json['id'] as String?,
  projectId: json['projectId'] as String?,
  agentProfileId: json['agentProfileId'] as String?,
  title: json['title'] as String?,
  sessionId: json['sessionId'] as String?,
  model: json['model'] as String?,
  tokenUsage: json['tokenUsage'] == null
      ? null
      : TokenUsage.fromJson(json['tokenUsage'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ThreadToJson(Thread instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'agentProfileId': instance.agentProfileId,
  'title': instance.title,
  'sessionId': instance.sessionId,
  'model': instance.model,
  'tokenUsage': instance.tokenUsage,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

CreateThreadRequest _$CreateThreadRequestFromJson(Map<String, dynamic> json) =>
    CreateThreadRequest(
      projectId: json['projectId'] as String,
      message: json['message'] as String,
      agentProfileId: json['agentProfileId'] as String?,
      title: json['title'] as String?,
      model: json['model'] as String?,
    );

Map<String, dynamic> _$CreateThreadRequestToJson(
  CreateThreadRequest instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  'message': instance.message,
  'agentProfileId': instance.agentProfileId,
  'title': instance.title,
  'model': instance.model,
};

ThreadReplyRequest _$ThreadReplyRequestFromJson(Map<String, dynamic> json) =>
    ThreadReplyRequest(message: json['message'] as String);

Map<String, dynamic> _$ThreadReplyRequestToJson(ThreadReplyRequest instance) =>
    <String, dynamic>{'message': instance.message};
