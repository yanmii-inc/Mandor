import type { Complexity, PreflightResult } from '../agents/base';

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

export async function runPreflight(description: string, apiKey?: string): Promise<PreflightResult> {
  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey ?? process.env['ANTHROPIC_API_KEY'] ?? '',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
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
  } catch (err) {
    return {
      complexity: 'medium',
      estimated_tokens: { min: 1000, max: 5000 },
      reasoning: `Preflight failed, defaulting to medium: ${err instanceof Error ? err.message : String(err)}`,
    };
  }
}
