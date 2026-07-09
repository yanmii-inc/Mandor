import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'mandor_providers.dart';

/// All configured agent profiles — each is one "agent" the user can switch to
/// (Claude, GLM, Gemini, Opencode, …), exactly like picking an IDE extension.
final agentProfilesProvider = FutureProvider<List<AgentProfile>>((ref) async {
  final client = ref.watch(mandorApiClientProvider);
  return client.getAgentProfiles();
});

/// The models a single agent profile supports, discovered live from the agent.
/// `freeForm == true` means the agent exposes no list (CLI agents) and the user
/// types the model string freehand. Use `''` as the key when no profile is set.
final profileModelsProvider =
    FutureProvider.family<ProfileModels, String>((ref, profileId) async {
  if (profileId.isEmpty) {
    return const ProfileModels(models: [], freeForm: true);
  }
  final client = ref.watch(mandorApiClientProvider);
  return client.getProfileModels(profileId);
});

/// What the user has chosen for the next thread/task: which agent (profile) and
/// which model. In-memory only — resets on app restart.
class ModelSelectionState {
  final String? agentProfileId;
  final String? agentProfileName;
  final String? modelId;
  final String? modelLabel;

  const ModelSelectionState({
    this.agentProfileId,
    this.agentProfileName,
    this.modelId,
    this.modelLabel,
  });

  bool get hasSelection => agentProfileId != null || modelId != null;
}

class ModelSelectionNotifier extends StateNotifier<ModelSelectionState> {
  ModelSelectionNotifier() : super(const ModelSelectionState());

  /// Switch agent. Resets the model, since each agent has its own model set.
  void selectProfile(String profileId, String profileName) {
    state = ModelSelectionState(
      agentProfileId: profileId,
      agentProfileName: profileName,
    );
  }

  void selectModel(ModelInfo model) {
    state = ModelSelectionState(
      agentProfileId: state.agentProfileId,
      agentProfileName: state.agentProfileName,
      modelId: model.id,
      modelLabel: model.label,
    );
  }

  /// Free-form model entry (CLI agents that accept any `provider/model` string).
  void selectModelId(String modelId) {
    state = ModelSelectionState(
      agentProfileId: state.agentProfileId,
      agentProfileName: state.agentProfileName,
      modelId: modelId,
      modelLabel: modelId,
    );
  }

  void clear() => state = const ModelSelectionState();
}

final modelSelectionProvider =
    StateNotifierProvider<ModelSelectionNotifier, ModelSelectionState>((ref) {
  return ModelSelectionNotifier();
});
