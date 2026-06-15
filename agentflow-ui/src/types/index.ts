export type Project = {
  id: string
  name: string
  repo_url: string
  local_path?: string
  agent_profile_id?: string | null
  deploy_config?: string | null
}

export type AgentProfile = {
  id: string
  name: string
  agent_type: 'claude' | 'opencode' | 'aider' | 'cline' | 'copilot'
  cli_path?: string
  credentials_encrypted?: string | null
}

export type TaskStatus = 'pending' | 'running' | 'pr_ready' | 'merged' | 'failed'

export type Task = {
  id: string
  project_id: string
  agent_profile_id?: string | null
  description: string
  status: TaskStatus
  created_at?: string
  updated_at?: string
  branch?: string
  pr_url?: string | null
  token_usage?: { input: number; output: number; total: number } | null
}

export type TaskLog = {
  id: string
  task_id: string
  role: 'agent' | 'system' | 'user'
  chunk: string
  timestamp: string
}

export type TokensSummary = {
  total_input: number
  total_output: number
  total_tokens: number
  task_count: number
}
