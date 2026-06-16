import type { AgentType } from './base';

export interface ModelOption {
  id: string;
  label: string;
}

/**
 * Selectable models per provider. The first entry for each provider is its default.
 * Providers driven by an external CLI (opencode, aider, cline, copilot) don't expose
 * model selection here — they manage models through their own configuration.
 */
export const PROVIDER_MODELS: Partial<Record<AgentType, ModelOption[]>> = {
  claude: [
    { id: 'claude-sonnet-4-5-20250929', label: 'Claude Sonnet 4.5' },
    { id: 'claude-opus-4-20250514', label: 'Claude Opus 4' },
    { id: 'claude-3-5-haiku-20241022', label: 'Claude 3.5 Haiku' },
  ],
  gemini: [
    { id: 'gemini-2.0-flash', label: 'Gemini 2.0 Flash' },
    { id: 'gemini-1.5-pro', label: 'Gemini 1.5 Pro' },
    { id: 'gemini-1.5-flash', label: 'Gemini 1.5 Flash' },
  ],
  glm: [
    { id: 'glm-4-air', label: 'GLM-4 Air' },
    { id: 'glm-4-plus', label: 'GLM-4 Plus' },
    { id: 'glm-4-flash', label: 'GLM-4 Flash' },
  ],
};

/**
 * Cheap models used for the preflight complexity classifier — no need to spend the
 * task's main model on a quick JSON classification.
 */
export const PREFLIGHT_MODELS: Record<'anthropic' | 'gemini' | 'glm', string> = {
  anthropic: 'claude-3-haiku-20240307',
  gemini: 'gemini-1.5-flash',
  glm: 'glm-4-flash',
};

export function getDefaultModel(agentType: AgentType): string | undefined {
  return PROVIDER_MODELS[agentType]?.[0]?.id;
}

export function isValidModel(agentType: AgentType, model: string): boolean {
  const models = PROVIDER_MODELS[agentType];
  if (!models) return false;
  return models.some(m => m.id === model);
}
