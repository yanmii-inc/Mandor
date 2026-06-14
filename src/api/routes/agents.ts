import type { Db } from '../../db/index';
import type { CreateAgentProfileInput } from '../../agents/base';

export function handleAgents(req: Request, db: Db): Response | Promise<Response> {
  if (req.method === 'POST') {
    return createAgentProfile(req, db);
  }

  if (req.method === 'GET') {
    const profiles = db.listAgentProfiles();
    return Response.json(profiles, { status: 200 });
  }

  return new Response('Method not allowed', { status: 405 });
}

async function createAgentProfile(req: Request, db: Db): Promise<Response> {
  try {
    const body = await req.json() as CreateAgentProfileInput;

    if (!body.name || !body.agent_type) {
      return Response.json({ error: 'name and agent_type are required' }, { status: 400 });
    }

    const validTypes = ['claude', 'opencode', 'aider', 'cline', 'copilot'];
    if (!validTypes.includes(body.agent_type)) {
      return Response.json({ error: `agent_type must be one of: ${validTypes.join(', ')}` }, { status: 400 });
    }

    const profile = db.createAgentProfile(body);
    return Response.json(profile, { status: 201 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}
