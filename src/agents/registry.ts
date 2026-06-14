import type { AgentAdapter, AgentProfile, AgentType } from './base';
import { ClaudeAdapter } from './claude';
import { OpenCodeAdapter } from './opencode';
import { AiderAdapter } from './aider';
import type { Db } from '../db/index';

export class AgentRegistry {
  private db: Db;

  constructor(db: Db) {
    this.db = db;
  }

  resolve(profile: AgentProfile): AgentAdapter {
    switch (profile.agent_type) {
      case 'claude':
        return new ClaudeAdapter(this.db);
      case 'opencode':
        return new OpenCodeAdapter();
      case 'aider':
        return new AiderAdapter();
      default:
        return new OpenCodeAdapter();
    }
  }

  resolveByType(type: AgentType): AgentAdapter {
    switch (type) {
      case 'claude':
        return new ClaudeAdapter(this.db);
      case 'opencode':
        return new OpenCodeAdapter();
      case 'aider':
        return new AiderAdapter();
      default:
        return new OpenCodeAdapter();
    }
  }
}
