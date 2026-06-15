import type { Project, AgentProfile, Task, TokensSummary } from '../types'

const getBase = () => localStorage.getItem('api_base') || 'http://localhost:3000'

async function request<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const base = getBase()
  const token = localStorage.getItem('auth_token') || ''
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
    ...((opts && opts.headers) as Record<string,string> | undefined),
  }
  const res = await fetch(`${base}${path}`, { ...opts, headers })
  if (res.status === 401) {
    window.location.href = '/setup'
    throw new Error('Unauthorized')
  }
  if (res.status === 204) return null as unknown as T
  if (!res.ok) {
    const text = await res.text()
    throw new Error(text || res.statusText)
  }
  return res.json()
}

export const apiClient = {
  getProjects: (): Promise<Project[]> => request('/projects'),
  createProject: (body: Partial<Project>) => request('/projects', { method: 'POST', body: JSON.stringify(body) }),
  getAgentProfiles: (): Promise<AgentProfile[]> => request('/agent-profiles'),
  createAgentProfile: (body: Partial<AgentProfile>) => request('/agent-profiles', { method: 'POST', body: JSON.stringify(body) }),
  createTask: (body: { project_id: string; agent_profile_id?: string; description: string }) => request('/tasks', { method: 'POST', body: JSON.stringify(body) }),
  getTasks: (project_id?: string): Promise<Task[]> => request(`/tasks${project_id ? `?project_id=${project_id}` : ''}`),
  getTask: (id: string): Promise<Task> => request(`/tasks/${id}`),
  confirmTask: (id: string) => request(`/tasks/${id}/confirm`, { method: 'POST' }),
  replyTask: (id: string, message: string) => request(`/tasks/${id}/reply`, { method: 'POST', body: JSON.stringify({ message }) }),
  deleteTask: (id: string) => request(`/tasks/${id}`, { method: 'DELETE' }),
  getTokens: (): Promise<TokensSummary> => request('/tokens'),
}
