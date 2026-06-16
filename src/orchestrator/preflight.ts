import type { Complexity, PreflightResult } from '../agents/base';
import { PREFLIGHT_MODELS } from '../agents/models';

const SYSTEM_PROMPT = `You are a task complexity classifier for an AI coding agent orchestrator.
Analyze the given task description and classify it as one of:
- "simple": a well-defined task with clear requirements, few files, minimal risk (e.g., fixing a typo, adding a simple function, updating a config)
- "medium": moderately complex task requiring changes across a few files, some design decisions, moderate risk
- "complex": large task with significant architectural changes, many files, high risk, ambiguous requirements

Respond with a JSON object:
{
  "complexity": "simple" | "medium" | "complex",
  "estimated_tokens": { "min": number, "max": number },
  "reasoning": "brief explanation"
}`;

export async function runPreflight(description: string, apiKey?: string, provider: 'anthropic' | 'gemini' | 'glm' = 'anthropic'): Promise<PreflightResult> {
  try {
    if (provider === 'gemini') {
      return await runPreflightGemini(description, apiKey);
    } else if (provider === 'glm') {
      return await runPreflightGlm(description, apiKey);
    }
    return await runPreflightAnthropic(description, apiKey);
  } catch (err) {
    return {
      complexity: 'medium',
      estimated_tokens: { min: 1000, max: 5000 },
      reasoning: `Preflight failed, defaulting to medium: ${err instanceof Error ? err.message : String(err)}`,
    };
  }
}

async function runPreflightAnthropic(description: string, apiKey?: string): Promise<PreflightResult> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey ?? process.env['ANTHROPIC_API_KEY'] ?? '',
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: PREFLIGHT_MODELS.anthropic,
      max_tokens: 500,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: description }],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Preflight API error: ${response.status} ${text}`);
  }

  const data = await response.json() as any;
  const content = data.content?.[0]?.text ?? '';
  const parsed = JSON.parse(content) as PreflightResult;

  return {
    complexity: parsed.complexity ?? 'medium',
    estimated_tokens: parsed.estimated_tokens ?? { min: 1000, max: 5000 },
    reasoning: parsed.reasoning ?? '',
  };
}

async function runPreflightGemini(description: string, apiKey?: string): Promise<PreflightResult> {
  const key = apiKey ?? process.env['GEMINI_API_KEY'] ?? '';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${PREFLIGHT_MODELS.gemini}:generateContent?key=${key}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
      contents: [{ role: 'user', parts: [{ text: description }] }],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini API error: ${response.status} ${text}`);
  }

  const data = await response.json() as any;
  const textParts = data.candidates?.[0]?.content?.parts?.filter((p: any) => 'text' in p) ?? [];
  const content = textParts.map((p: any) => p.text).join('\n');
  const parsed = JSON.parse(content) as PreflightResult;

  return {
    complexity: parsed.complexity ?? 'medium',
    estimated_tokens: parsed.estimated_tokens ?? { min: 1000, max: 5000 },
    reasoning: parsed.reasoning ?? '',
  };
}

async function runPreflightGlm(description: string, apiKey?: string): Promise<PreflightResult> {
  const key = apiKey ?? process.env['GLM_API_KEY'] ?? '';

  const response = await fetch('https://open.bigmodel.cn/api/paas/v4/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({
      model: PREFLIGHT_MODELS.glm,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: description },
      ],
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`GLM API error: ${response.status} ${text}`);
  }

  const data = await response.json() as any;
  const content = data.choices?.[0]?.message?.content ?? '';
  const parsed = JSON.parse(content) as PreflightResult;

  return {
    complexity: parsed.complexity ?? 'medium',
    estimated_tokens: parsed.estimated_tokens ?? { min: 1000, max: 5000 },
    reasoning: parsed.reasoning ?? '',
  };
}
