import simpleGit from 'simple-git';
import { existsSync, rmSync } from 'fs';
import { join } from 'path';

export interface WorktreeResult {
  path: string;
  branch: string;
}

export class WorktreeManager {
  private git;
  private repoPath: string;

  constructor(repoPath: string) {
    this.repoPath = repoPath;
    this.git = simpleGit(repoPath);
  }

  async create(taskId: string, description: string): Promise<WorktreeResult> {
    const slug = description
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .slice(0, 40);

    const branch = `agent/${taskId}-${slug}`;
    const worktreePath = join(this.repoPath, '..', `.worktrees/${taskId}`);

    const exists = await this.git.branch(['--list', branch]);
    if (!exists) {
      await this.git.checkoutLocalBranch(branch);
    } else {
      await this.git.checkout(branch);
    }

    await this.git.raw(['worktree', 'add', worktreePath, branch]);

    return { path: worktreePath, branch };
  }

  async commitAndPush(worktreePath: string, branch: string): Promise<void> {
    const wtGit = simpleGit(worktreePath);
    const status = await wtGit.status();

    if (status.files.length > 0) {
      await wtGit.add('.');
      await wtGit.commit('agentflow: agent task completed');
    }

    await wtGit.push('origin', branch);
  }

  async openPr(worktreePath: string, branch: string, taskDescription: string): Promise<string> {
    const wtGit = simpleGit(worktreePath);
    const remotes = await wtGit.getRemotes(true);
    const origin = remotes.find(r => r.name === 'origin');

    if (!origin) {
      throw new Error('No remote "origin" configured');
    }

    const repoFullName = origin.refs.push
      .replace(/^git@[^:]+:|https:\/\/[^\/]+\//, '')
      .replace(/\.git$/, '')
      .trim();

    const title = `agentflow: ${taskDescription.slice(0, 72)}${taskDescription.length > 72 ? '...' : ''}`;

    const ghProcess = Bun.spawnSync([
      'gh', 'pr', 'create',
      '--repo', repoFullName,
      '--head', branch,
      '--title', title,
      '--body', `This PR was created by agentflow.\n\n**Task description:**\n\n${taskDescription}`,
    ]);

    const prUrl = ghProcess.stdout.toString().trim();
    return prUrl;
  }

  async cleanup(worktreePath: string, branch: string): Promise<void> {
    try {
      await this.git.raw(['worktree', 'remove', worktreePath]);
    } catch {}

    try {
      if (existsSync(worktreePath)) {
        rmSync(worktreePath, { recursive: true, force: true });
      }
    } catch {}

    try {
      await this.git.branch(['-D', branch]);
    } catch {}

    try {
      await this.git.push(['origin', '--delete', branch]);
    } catch {}
  }
}
