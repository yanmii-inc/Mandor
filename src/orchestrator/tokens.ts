import type { TokenUsage } from '../agents/base';

export interface TokenTracker {
  taskId: string;
  usage: TokenUsage;
}

const trackers = new Map<string, TokenTracker>();

export function createTokenTracker(taskId: string): TokenTracker {
  const tracker: TokenTracker = { taskId, usage: { input: 0, output: 0, total: 0 } };
  trackers.set(taskId, tracker);
  return tracker;
}

export function updateTokenUsage(taskId: string, usage: Partial<TokenUsage>): TokenTracker | undefined {
  const tracker = trackers.get(taskId);
  if (!tracker) return undefined;
  if (usage.input != null) tracker.usage.input += usage.input;
  if (usage.output != null) tracker.usage.output += usage.output;
  tracker.usage.total = tracker.usage.input + tracker.usage.output;
  return tracker;
}

export function getTokenUsage(taskId: string): TokenUsage | undefined {
  return trackers.get(taskId)?.usage;
}

export function removeTokenTracker(taskId: string): void {
  trackers.delete(taskId);
}
