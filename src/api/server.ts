import type { Db } from '../db/index';
import { Orchestrator } from '../orchestrator/index';
import { handleProjects } from './routes/projects';
import { handleAgents } from './routes/agents';
import { handleTasks } from './routes/tasks';
import { handleTokens } from './routes/tokens';

export class ApiServer {
  private db: Db;
  private orchestrator: Orchestrator;
  private server: ReturnType<typeof Bun.serve> | null = null;

  constructor(db: Db) {
    this.db = db;
    this.orchestrator = new Orchestrator(db);
  }

  start(port: number = 3000, hostname: string = '0.0.0.0'): void {
    this.server = Bun.serve({
      port,
      hostname,
      fetch: (req) => this.handleRequest(req),
    });

    console.log(`agentflow API server running on http://${hostname}:${port}`);
  }

  stop(): void {
    if (this.server) {
      this.server.stop();
      this.server = null;
    }
  }

  private handleRequest(req: Request): Response | Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname;

    try {
      if (path === '/projects' || path.startsWith('/projects/')) {
        return handleProjects(req, this.db);
      }

      if (path === '/agent-profiles' || path.startsWith('/agent-profiles/')) {
        return handleAgents(req, this.db);
      }

      if (path === '/tasks' || path.startsWith('/tasks/')) {
        return handleTasks(req, this.db, this.orchestrator);
      }

      if (path === '/tokens') {
        return handleTokens(req, this.db);
      }

      return Response.json({ error: 'Not found' }, { status: 404 });
    } catch (err: any) {
      return Response.json({ error: err.message }, { status: 500 });
    }
  }
}
