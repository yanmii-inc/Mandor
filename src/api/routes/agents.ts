import type { Db } from '../../db/index';
import type { AgentType, CreateAgentProfileInput } from '../../agents/base';
import type { ModelOption } from '../../agents/models';
import { AgentRegistry } from '../../agents/registry';

const VALID_TYPES: AgentType[] = ['claude', 'opencode', 'aider', 'cline', 'copilot', 'gemini', 'glm'];

/** In-memory model-discovery cache: profileId → { models, fetchedAt }. TTL-bounded. */
const modelCache = new Map<string, { models: ModelOption[]; at: number }>();
const MODEL_CACHE_TTL_MS = 10 * 60 * 1000;

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

  // /agent-profiles/:id/models
  if (pathParts.length === 3 && pathParts[2] === 'models') {
    const id = pathParts[1];
    if (req.method === 'GET') return getProfileModels(id, req, db);
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

    if (body.model === '') {
      return Response.json({ error: 'model must not be empty' }, { status: 400 });
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

    if (body.model === '') {
      return Response.json({ error: 'model must not be empty' }, { status: 400 });
    }

    // Credentials changed → cached model list may now belong to a different key.
    if (body.credentials_encrypted !== undefined) {
      modelCache.delete(id);
    }

    const updated = db.updateAgentProfile(id, body);
    return Response.json(updated, { status: 200 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}

/**
 * GET /agent-profiles/:id/models[?refresh=true] — discover the models the
 * profile's agent supports, via the adapter's `listModels()`. API-backed agents
 * query their provider; CLI-backed agents return `[]`. `freeForm` is true when
 * no list is available, signalling the client to render a free-text field.
 * Results are cached per profile for MODEL_CACHE_TTL_MS; `?refresh=true` bypasses.
 */
async function getProfileModels(id: string, req: Request, db: Db): Promise<Response> {
  const profile = db.getAgentProfile(id);
  if (!profile) return Response.json({ error: 'Agent profile not found' }, { status: 404 });

  const url = new URL(req.url);
  const forceRefresh = url.searchParams.get('refresh') === 'true';

  const cached = modelCache.get(id);
  if (!forceRefresh && cached && Date.now() - cached.at < MODEL_CACHE_TTL_MS) {
    return Response.json({ models: cached.models, freeForm: cached.models.length === 0 }, { status: 200 });
  }

  const registry = new AgentRegistry(db);
  const adapter = registry.resolve(profile);
  const apiKey = profile.credentials_encrypted ?? undefined;

  let models: ModelOption[] = [];
  try {
    models = await adapter.listModels(apiKey);
  } catch {
    models = [];
  }

  modelCache.set(id, { models, at: Date.now() });
  return Response.json({ models, freeForm: models.length === 0 }, { status: 200 });
}
