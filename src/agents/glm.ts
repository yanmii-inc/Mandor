import type { AgentAdapter, AgentMessage, TokenUsage, Task } from './base';
import type { Db } from '../db/index';
import { executeTool, TOOL_DEFINITIONS, AGENT_SYSTEM_PROMPT, type ToolCall } from './llm-coding-tools';

const GLM_BASE = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
const DEFAULT_MODEL = 'glm-4-air';
const MAX_TURNS = 50;

interface OpenAiMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string | null;
  tool_calls?: Array<{
    id: string;
    type: 'function';
    function: { name: string; arguments: string };
  }>;
  tool_call_id?: string;
  name?: string;
}

interface OpenAiResponse {
  choices?: Array<{
    message: OpenAiMessage;
    finish_reason?: string;
  }>;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
  };
  error?: { message: string };
}

export class GlmAdapter implements AgentAdapter {
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
    const apiKey = profile?.credentials_encrypted ?? process.env['GLM_API_KEY'] ?? '';
    const model = profile?.cli_path ?? DEFAULT_MODEL;

    this.streamActive = true;
    this.runAgentLoop(prompt ?? task.description, worktreePath, apiKey, model).catch(() => {});
  }

  async resume(_sessionId: string, _message: string): Promise<void> {
    throw new Error('Session resume not supported for GLM adapter');
  }

  private async runAgentLoop(
    taskDescription: string,
    cwd: string,
    apiKey: string,
    model: string,
  ): Promise<void> {
    const messages: OpenAiMessage[] = [
      { role: 'system', content: AGENT_SYSTEM_PROMPT },
      { role: 'user', content: taskDescription },
    ];

    try {
      for (let turn = 0; turn < MAX_TURNS; turn++) {
        if (this.abortController.signal.aborted) break;

        const response = await this.callApi(messages, apiKey, model);

        if (response.error) {
          this.messageQueue.push({ type: 'error', content: response.error.message, timestamp: new Date() });
          break;
        }

        const usage = response.usage;
        if (usage) {
          this.tokenUsage.input += usage.prompt_tokens ?? 0;
          this.tokenUsage.output += usage.completion_tokens ?? 0;
          this.tokenUsage.total = this.tokenUsage.input + this.tokenUsage.output;
        }

        const choice = response.choices?.[0];
        if (!choice) break;

        const assistantMsg = choice.message;
        messages.push(assistantMsg);

        if (assistantMsg.content) {
          this.messageQueue.push({ type: 'text', content: assistantMsg.content, timestamp: new Date() });
        }

        const toolCalls = assistantMsg.tool_calls ?? [];
        if (toolCalls.length === 0) break;

        for (const tc of toolCalls) {
          let args: Record<string, unknown> = {};
          try { args = JSON.parse(tc.function.arguments); } catch {}

          const toolCall: ToolCall = { id: tc.id, name: tc.function.name, args };

          this.messageQueue.push({
            type: 'tool_use',
            content: `${tc.function.name}(${tc.function.arguments})`,
            timestamp: new Date(),
          });

          const result = await executeTool(toolCall, cwd);
          messages.push({
            role: 'tool',
            content: result.result,
            tool_call_id: tc.id,
            name: tc.function.name,
          });
        }
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
    messages: OpenAiMessage[],
    apiKey: string,
    model: string,
  ): Promise<OpenAiResponse> {
    const body = {
      model,
      messages,
      tools: TOOL_DEFINITIONS.map(t => ({
        type: 'function' as const,
        function: { name: t.name, description: t.description, parameters: t.parameters },
      })),
      tool_choice: 'auto',
    };

    const response = await fetch(GLM_BASE, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
      signal: this.abortController.signal,
    });

    if (!response.ok) {
      const text = await response.text();
      return { error: { message: `GLM API error ${response.status}: ${text}` } };
    }

    return response.json() as Promise<OpenAiResponse>;
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
