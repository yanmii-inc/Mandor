import type { Db } from '../db/index';
import type { AgentAdapter, Task, AgentMessage } from '../agents/base';
import { AgentRegistry } from '../agents/registry';
import { WorktreeManager } from './worktree';
import { runPreflight } from './preflight';
import { createTokenTracker, updateTokenUsage } from './tokens';

export interface RunningTask {
  task: Task;
  adapter: AgentAdapter;
  abortController: AbortController;
}

const runningTasks = new Map<string, RunningTask>();
const sseClients = new Map<string, Set<(msg: AgentMessage) => void>>();

export class Orchestrator {
  private db: Db;
  private registry: AgentRegistry;

  constructor(db: Db) {
    this.db = db;
    this.registry = new AgentRegistry(db);
  }

  async dispatchTask(taskId: string): Promise<void> {
    const task = this.db.getTask(taskId);
    if (!task) throw new Error(`Task ${taskId} not found`);

    const project = this.db.getProject(task.project_id);
    if (!project) throw new Error(`Project ${task.project_id} not found`);

    // Preflight
    const preflight = await runPreflight(task.description);
    this.db.updateTask(task.id, { complexity: preflight.complexity });

    if (preflight.complexity === 'complex' && !task.confirmed) {
      return;
    }

    this.db.updateTask(task.id, { status: 'running' });

    // Create worktree
    const wt = new WorktreeManager(project.local_path);
    const { path: worktreePath, branch } = await wt.create(taskId, task.description);
    this.db.updateTask(task.id, { worktree_path: worktreePath, branch_name: branch });

    // Resolve and start agent
    const profile = task.agent_profile_id
      ? this.db.getAgentProfile(task.agent_profile_id)
      : undefined;

    const adapter = profile
      ? this.registry.resolve(profile)
      : task.agent_profile_id
        ? this.registry.resolveByType('claude')
        : this.registry.resolveByType('claude');

    const abort = new AbortController();

    await adapter.start(task, worktreePath);

    const rt: RunningTask = { task, adapter, abortController: abort };
    runningTasks.set(taskId, rt);

    const tracker = createTokenTracker(taskId);
    createTokenTracker(taskId);

    // Stream processing
    this.processStream(taskId, adapter, wt, project.local_path);
  }

  private async processStream(taskId: string, adapter: AgentAdapter, wt: WorktreeManager, repoPath: string): Promise<void> {
    const task = this.db.getTask(taskId)!;

    try {
      let sessionId: string | null = null;

      for await (const message of adapter.stream()) {
        this.broadcastToSSEClients(taskId, message);

        if (message.type === 'text') {
          this.db.appendLog(taskId, 'agent', message.content);

          // Extract session_id from Claude SDK
          try {
            const parsed = JSON.parse(message.content);
            if (parsed.session_id) {
              sessionId = parsed.session_id;
            }
          } catch {}
        }

        if (message.type === 'tool_use') {
          this.db.appendLog(taskId, 'agent', `[tool_use] ${message.content}`);
        }

        if (message.type === 'done') {
          const usage = adapter.getTokenUsage();
          updateTokenUsage(taskId, usage);
          this.db.updateTask(taskId, {
            status: 'pr_ready',
            token_usage: JSON.stringify(usage),
            session_id: sessionId,
          });

          // Commit, push, create PR
          const currentTask = this.db.getTask(taskId);
          if (currentTask?.branch_name && currentTask?.worktree_path) {
            await wt.commitAndPush(currentTask.worktree_path, currentTask.branch_name);
            const prUrl = await wt.openPr(currentTask.worktree_path, currentTask.branch_name, currentTask.description);
            this.db.updateTask(taskId, { pr_url: prUrl });
            await wt.cleanup(currentTask.worktree_path, currentTask.branch_name);
          }
        }

        if (message.type === 'error') {
          this.db.appendLog(taskId, 'agent', `[error] ${message.content}`);
          this.db.updateTask(taskId, { status: 'failed' });
          const currentTask = this.db.getTask(taskId);
          if (currentTask?.worktree_path && currentTask?.branch_name) {
            await wt.cleanup(currentTask.worktree_path, currentTask.branch_name);
          }
        }
      }
    } catch (err: any) {
      if (err.name !== 'AbortError') {
        const msg = err.message ?? String(err);
        this.db.appendLog(taskId, 'agent', `[error] ${msg}`);
        this.db.updateTask(taskId, { status: 'failed' });
        const currentTask = this.db.getTask(taskId);
        if (currentTask?.worktree_path && currentTask?.branch_name) {
          await wt.cleanup(currentTask.worktree_path, currentTask.branch_name);
        }
      }
    } finally {
      runningTasks.delete(taskId);
    }
  }

  async reply(taskId: string, message: string): Promise<void> {
    this.db.appendLog(taskId, 'user', message);

    const running = runningTasks.get(taskId);
    if (running) {
      // Active agent, resume via SDK
      const task = this.db.getTask(taskId);
      if (task?.session_id) {
        await running.adapter.resume(task.session_id, message);
        this.processStream(taskId, running.adapter, new WorktreeManager(''), '');
      }
    } else {
      // Task is completed / waiting — re-create context
      throw new Error('Task not currently running; resume not implemented for completed tasks');
    }
  }

  async killTask(taskId: string): Promise<void> {
    const running = runningTasks.get(taskId);
    if (running) {
      await running.adapter.kill();
      running.abortController.abort();
      runningTasks.delete(taskId);
    }

    const task = this.db.getTask(taskId);
    if (task?.worktree_path && task?.branch_name) {
      const project = this.db.getProject(task.project_id);
      if (project) {
        const wt = new WorktreeManager(project.local_path);
        await wt.cleanup(task.worktree_path, task.branch_name);
      }
    }

    this.db.updateTask(taskId, { status: 'failed' });
  }

  // ── SSE ───────────────────────────────────────────────────

  subscribeToSSE(taskId: string, callback: (msg: AgentMessage) => void): () => void {
    if (!sseClients.has(taskId)) {
      sseClients.set(taskId, new Set());
    }
    sseClients.get(taskId)!.add(callback);
    return () => sseClients.get(taskId)?.delete(callback);
  }

  private broadcastToSSEClients(taskId: string, message: AgentMessage): void {
    const clients = sseClients.get(taskId);
    if (clients) {
      for (const cb of clients) {
        try { cb(message); } catch {}
      }
    }
  }
}
