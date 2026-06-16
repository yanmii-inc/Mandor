import type { AgentAdapter, AgentMessage, TokenUsage, Task } from './base';
import type { Db } from '../db/index';
import { executeTool, TOOL_DEFINITIONS, AGENT_SYSTEM_PROMPT, type ToolCall } from './llm-coding-tools';

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const DEFAULT_MODEL = 'gemini-2.0-flash';
const MAX_TURNS = 50;

type GeminiPart =
  | { text: string }
  | { functionCall: { name: string; args: Record<string, unknown> } }
  | { functionResponse: { name: string; response: { content: string } } };

interface GeminiContent {
  role: 'user' | 'model';
  parts: GeminiPart[];
}

interface GeminiResponse {
  candidates?: Array<{
    content: GeminiContent;
    finishReason?: string;
  }>;
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
  };
  error?: { message: string };
}

export class GeminiAdapter implements AgentAdapter {
  private db: Db;
  private tokenUsage: TokenUsage = { input: 0, output: 0, total: 0 };
  private messageQueue: AgentMessage[] = [];
  private streamActive = false;
  private abortController: AbortController = new AbortController();

  constructor(db: Db) {
    this.db = db;
  }

  async start(task: Task, worktreePath: string, prompt?: string): Promise<void> {
    this.abortController = new AbortController();
    this.messageQueue = [];
    this.tokenUsage = { input: 0, output: 0, total: 0 };

    const profile = task.agent_profile_id ? this.db.getAgentProfile(task.agent_profile_id) : undefined;
    const apiKey = profile?.credentials_encrypted ?? process.env['GEMINI_API_KEY'] ?? '';
    const model = profile?.cli_path ?? DEFAULT_MODEL;

    this.streamActive = true;
    this.runAgentLoop(prompt ?? task.description, worktreePath, apiKey, model).catch(() => {});
  }

  async resume(_sessionId: string, _message: string): Promise<void> {
    throw new Error('Session resume not supported for Gemini adapter');
  }

  private async runAgentLoop(
    taskDescription: string,
    cwd: string,
    apiKey: string,
    model: string,
  ): Promise<void> {
    const contents: GeminiContent[] = [
      { role: 'user', parts: [{ text: taskDescription }] },
    ];

    try {
      for (let turn = 0; turn < MAX_TURNS; turn++) {
        if (this.abortController.signal.aborted) break;

        const response = await this.callApi(contents, apiKey, model);

        if (response.error) {
          this.messageQueue.push({ type: 'error', content: response.error.message, timestamp: new Date() });
          break;
        }

        const usage = response.usageMetadata;
        if (usage) {
          this.tokenUsage.input += usage.promptTokenCount ?? 0;
          this.tokenUsage.output += usage.candidatesTokenCount ?? 0;
          this.tokenUsage.total = this.tokenUsage.input + this.tokenUsage.output;
        }

        const candidate = response.candidates?.[0];
        if (!candidate) break;

        const assistantContent = candidate.content;
        contents.push(assistantContent);

        const textParts = assistantContent.parts.filter((p): p is { text: string } => 'text' in p);
        const text = textParts.map(p => p.text).join('\n').trim();
        if (text) {
          this.messageQueue.push({ type: 'text', content: text, timestamp: new Date() });
        }

        const fnCalls = assistantContent.parts.filter(
          (p): p is { functionCall: { name: string; args: Record<string, unknown> } } => 'functionCall' in p,
        );

        if (fnCalls.length === 0) break;

        const toolResultParts: GeminiPart[] = [];
        for (const fc of fnCalls) {
          const toolCall: ToolCall = {
            id: `${fc.functionCall.name}-${turn}`,
            name: fc.functionCall.name,
            args: fc.functionCall.args,
          };

          this.messageQueue.push({
            type: 'tool_use',
            content: `${fc.functionCall.name}(${JSON.stringify(fc.functionCall.args)})`,
            timestamp: new Date(),
          });

          const result = await executeTool(toolCall, cwd);
          toolResultParts.push({
            functionResponse: {
              name: fc.functionCall.name,
              response: { content: result.result },
            },
          });
        }

        contents.push({ role: 'user', parts: toolResultParts });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      if (!this.abortController.signal.aborted) {
        this.messageQueue.push({ type: 'error', content: msg, timestamp: new Date() });
      }
    }

    this.messageQueue.push({ type: 'done', content: '', timestamp: new Date() });
    this.streamActive = false;
  }

  private async callApi(
    contents: GeminiContent[],
    apiKey: string,
    model: string,
  ): Promise<GeminiResponse> {
    const url = `${GEMINI_BASE}/${model}:generateContent?key=${apiKey}`;
    const body = {
      systemInstruction: { parts: [{ text: AGENT_SYSTEM_PROMPT }] },
      contents,
      tools: [{
        functionDeclarations: TOOL_DEFINITIONS.map(t => ({
          name: t.name,
          description: t.description,
          parameters: t.parameters,
        })),
      }],
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: this.abortController.signal,
    });

    if (!response.ok) {
      const text = await response.text();
      return { error: { message: `Gemini API error ${response.status}: ${text}` } };
    }

    return response.json() as Promise<GeminiResponse>;
  }

  stream(): AsyncIterable<AgentMessage> {
    const self = this;
    return {
      [Symbol.asyncIterator]: async function* () {
        while (self.streamActive || self.messageQueue.length > 0) {
          if (self.messageQueue.length > 0) {
            yield self.messageQueue.shift()!;
          } else {
            await new Promise(resolve => setTimeout(resolve, 50));
          }
        }
      },
    };
  }

  getTokenUsage(): TokenUsage {
    return this.tokenUsage;
  }

  async kill(): Promise<void> {
    this.abortController.abort();
    this.streamActive = false;
  }
}
