import type { Db } from '../../db/index';
import type { CreateProjectInput } from '../../agents/base';

export function handleProjects(req: Request, db: Db): Response | Promise<Response> {
  if (req.method === 'POST') {
    return createProject(req, db);
  }

  if (req.method === 'GET') {
    const projects = db.listProjects();
    return Response.json(projects, { status: 200 });
  }

  return new Response('Method not allowed', { status: 405 });
}

async function createProject(req: Request, db: Db): Promise<Response> {
  try {
    const body = await req.json() as CreateProjectInput;

    if (!body.name || !body.repo_url || !body.local_path) {
      return Response.json({ error: 'name, repo_url, and local_path are required' }, { status: 400 });
    }

    const project = db.createProject(body);
    return Response.json(project, { status: 201 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}
