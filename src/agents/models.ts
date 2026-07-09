export interface ModelOption {
  id: string;
  label: string;
}

/**
 * Models are no longer curated here. Each agent adapter discovers what it
 * supports at runtime via `listModels()` — API-backed adapters (claude/gemini/
 * glm) query their provider's models endpoint; CLI-backed adapters return `[]`
 * (free-form, since they accept any `provider/model` string).
 */

/**
 * Cheap models used for the preflight complexity classifier — no need to spend the
 * task's main model on a quick JSON classification.
 */
export const PREFLIGHT_MODELS: Record<'anthropic' | 'gemini' | 'glm', string> = {
  anthropic: 'claude-3-haiku-20240307',
  gemini: 'gemini-1.5-flash',
  glm: 'glm-4.7-flash',
};

/**
 * Validation is lenient: with dynamic discovery there is no hardcoded catalog to
 * check against, and the discovered list can lag reality (a new model the picker
 * hasn't fetched yet). The provider/CLI is the real validator at runtime, so we
 * accept any model string here.
 */
export function isValidModel(_agentType: string, _model: string): boolean {
  return true;
}
