import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/model_selection_provider.dart';

/// A compact chip/button that shows the currently selected agent + model and
/// opens a picker to switch them. Agent choice maps to an agent profile; the
/// model list is whatever that agent supports (discovered live, or free-form for
/// CLI agents that accept any `provider/model` string).
class ModelSwitcher extends ConsumerWidget {
  const ModelSwitcher({super.key, this.iconOnly = true});

  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(modelSelectionProvider);
    final hasAgent = selection.agentProfileName != null;
    final label = [
      if (hasAgent) selection.agentProfileName,
      if (selection.modelLabel != null) selection.modelLabel,
    ].join(' · ');

    void open() => showDialog(
          context: context,
          builder: (_) => const _ModelPickerDialog(),
        );

    if (iconOnly) {
      return IconButton(
        icon: Icon(
          hasAgent ? Icons.tune : Icons.psychology_outlined,
          size: 22,
        ),
        tooltip: label.isEmpty ? 'Select agent & model' : label,
        onPressed: open,
      );
    }

    return ActionChip(
      avatar: const Icon(Icons.smart_toy_outlined, size: 16),
      label: Text(label.isEmpty ? 'Default' : label),
      onPressed: open,
    );
  }
}

class _ModelPickerDialog extends ConsumerStatefulWidget {
  const _ModelPickerDialog();

  @override
  ConsumerState<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends ConsumerState<_ModelPickerDialog> {
  late String? _profileId;
  late String? _profileName;
  late String? _modelId;
  late TextEditingController _freeFormCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(modelSelectionProvider);
    _profileId = s.agentProfileId;
    _profileName = s.agentProfileName;
    _modelId = s.modelId;
    _freeFormCtrl = TextEditingController(text: s.modelId ?? '');
  }

  @override
  void dispose() {
    _freeFormCtrl.dispose();
    super.dispose();
  }

  void _applyAndClose() {
    final notifier = ref.read(modelSelectionProvider.notifier);
    if (_profileId == null) {
      notifier.clear();
    } else {
      notifier.selectProfile(_profileId!, _profileName ?? _profileId!);
      final model = _modelId;
      if (model != null && model.isNotEmpty) {
        notifier.selectModelId(model);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(agentProfilesProvider);
    final modelsAsync = _profileId == null
        ? const AsyncValue<ProfileModels>.data(
            ProfileModels(models: [], freeForm: true))
        : ref.watch(profileModelsProvider(_profileId!));

    return AlertDialog(
      title: const Text('Agent & Model'),
      content: SizedBox(
        width: double.maxFinite,
        child: profilesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Failed to load agents: $e'),
          data: (profiles) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Agent (profile) selector ──
              DropdownButtonFormField<String?>(
                initialValue: _profileId,
                decoration: const InputDecoration(
                  labelText: 'Agent',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Use project default'),
                  ),
                  ...profiles.map(
                    (p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text('${p.name} (${p.agentType ?? '?'})'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _profileId = value;
                    _profileName = value == null
                        ? null
                        : profiles.firstWhere((p) => p.id == value).name;
                    // Reset model — each agent has its own model set.
                    _modelId = null;
                    _freeFormCtrl.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_profileId != null)
                SizedBox(
                  height: 300,
                  child: modelsAsync.when(
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Text('Failed to load models: $e'),
                    data: (pm) => _ModelList(
                      profileModels: pm,
                      selectedModelId: _modelId,
                      freeFormCtrl: _freeFormCtrl,
                      onFreeFormChanged: (v) {
                        setState(() {
                          _modelId = v;
                        });
                      },
                      onSelected: (m) => setState(() {
                        _modelId = m.id;
                      }),
                      onRefresh: () => ref.invalidate(
                          profileModelsProvider(_profileId!)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _applyAndClose,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Renders the model choices for the selected agent: a list when the agent
/// exposes models, a free-text field when it doesn't (`freeForm`).
class _ModelList extends StatelessWidget {
  const _ModelList({
    required this.profileModels,
    required this.selectedModelId,
    required this.freeFormCtrl,
    required this.onFreeFormChanged,
    required this.onSelected,
    required this.onRefresh,
  });

  final ProfileModels profileModels;
  final String? selectedModelId;
  final TextEditingController freeFormCtrl;
  final ValueChanged<String> onFreeFormChanged;
  final ValueChanged<ModelInfo> onSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Model',
                style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh model list',
              onPressed: onRefresh,
            ),
          ],
        ),
        Expanded(
          child: profileModels.freeForm || profileModels.models.isEmpty
              ? _FreeFormModelField(
                  controller: freeFormCtrl,
                  onChanged: onFreeFormChanged,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: profileModels.models.length,
                  itemBuilder: (context, i) {
                    final m = profileModels.models[i];
                    final selected = m.id == selectedModelId;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(m.label),
                      subtitle: Text(
                        m.id,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => onSelected(m),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FreeFormModelField extends StatelessWidget {
  const _FreeFormModelField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          labelText: 'Model',
          hintText: 'provider/model (e.g. anthropic/claude-sonnet-4-5)',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
