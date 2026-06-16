import type { Db } from '../../db/index';
import type { AgentType, CreateAgentProfileInput } from '../../agents/base';
import { PROVIDER_MODELS, isValidModel } from '../../agents/models';

const VALID_TYPES: AgentType[] = ['claude', 'opencode', 'aider', 'cline', 'copilot', 'gemini', 'glm'];

export function handleAgents(req: Request, db: Db): Response | Promise<Response> {
  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  // /agent-profiles
  if (pathParts.length === 1) {
    if (req.method === 'POST') return createAgentProfile(req, db);
    if (req.method === 'GET') {
      const profiles = db.listAgentProfiles();
      return Response.json(profiles, { status: 200 });
    }
    return new Response('Method not allowed', { status: 405 });
  }

  // /agent-profiles/:id
  if (pathParts.length === 2) {
    const id = pathParts[1];
    if (req.method === 'GET') {
      const profile = db.getAgentProfile(id);
      if (!profile) return Response.json({ error: 'Agent profile not found' }, { status: 404 });
      return Response.json(profile, { status: 200 });
    }
    if (req.method === 'PATCH' || req.method === 'PUT') return updateAgentProfile(id, req, db);
    return new Response('Method not allowed', { status: 405 });
  }

  return new Response('Not found', { status: 404 });
}

async function createAgentProfile(req: Request, db: Db): Promise<Response> {
  try {
    const body = await req.json() as CreateAgentProfileInput;

    if (!body.name || !body.agent_type) {
      return Response.json({ error: 'name and agent_type are required' }, { status: 400 });
    }

    if (!VALID_TYPES.includes(body.agent_type)) {
      return Response.json({ error: `agent_type must be one of: ${VALID_TYPES.join(', ')}` }, { status: 400 });
    }

    if (body.model !== undefined) {
      if (body.model === '') {
        return Response.json({ error: 'model must not be empty' }, { status: 400 });
      }
      if (body.model !== null && !isValidModel(body.agent_type, body.model)) {
        return Response.json(
          { error: modelError(body.agent_type, body.model) },
          { status: 400 },
        );
      }
    }

    const profile = db.createAgentProfile(body);
    return Response.json(profile, { status: 201 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}

async function updateAgentProfile(id: string, req: Request, db: Db): Promise<Response> {
  try {
    const existing = db.getAgentProfile(id);
    if (!existing) {
      return Response.json({ error: 'Agent profile not found' }, { status: 404 });
    }

    const body = await req.json() as Partial<Pick<CreateAgentProfileInput, 'name' | 'cli_path' | 'credentials_encrypted' | 'model'>>;

    if (body.model !== undefined) {
      if (body.model === '') {
        return Response.json({ error: 'model must not be empty' }, { status: 400 });
      }
      if (body.model !== null && !isValidModel(existing.agent_type, body.model)) {
        return Response.json(
          { error: modelError(existing.agent_type, body.model) },
          { status: 400 },
        );
      }
    }

    const updated = db.updateAgentProfile(id, body);
    return Response.json(updated, { status: 200 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}

function modelError(agentType: AgentType, model: string): string {
  const allowed = PROVIDER_MODELS[agentType]?.map(m => m.id).join(', ') ?? '(none)';
  return `model "${model}" is not valid for agent_type "${agentType}". Allowed: ${allowed}`;
}
