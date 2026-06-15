import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { apiClient } from '../api/client'

export default function NewTask() {
  const [projects, setProjects] = useState<any[]>([])
  const [profiles, setProfiles] = useState<any[]>([])
  const [projectId, setProjectId] = useState('')
  const [profileId, setProfileId] = useState('')
  const [description, setDescription] = useState('')
  const navigate = useNavigate()

  useEffect(()=>{ apiClient.getProjects().then(setProjects); apiClient.getAgentProfiles().then(setProfiles)},[])

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const body = { project_id: projectId || projects[0]?.id, agent_profile_id: profileId || undefined, description }
    const task = await apiClient.createTask(body)
    navigate(`/tasks/${task.id}`)
  }

  return (
    <form onSubmit={submit} className="p-4">
      <h2 className="text-lg font-semibold mb-2">New Task</h2>
      <label className="block text-xs text-gray-400 mb-1">Project</label>
      <select value={projectId} onChange={(e)=>setProjectId(e.target.value)} className="w-full p-2 bg-gray-800 mb-3">
        {projects.map(p=> <option key={p.id} value={p.id}>{p.name}</option>)}
      </select>

      <label className="block text-xs text-gray-400 mb-1">Agent profile</label>
      <select value={profileId} onChange={(e)=>setProfileId(e.target.value)} className="w-full p-2 bg-gray-800 mb-3">
        <option value="">(default)</option>
        {profiles.map(p=> <option key={p.id} value={p.id}>{p.name} — {p.agent_type}</option>)}
      </select>

      <label className="block text-xs text-gray-400 mb-1">Description</label>
      <textarea value={description} onChange={(e)=>setDescription(e.target.value)} rows={8} className="w-full p-3 bg-gray-800 mb-3" />

      <button type="submit" className="w-full py-3 bg-indigo-600 rounded">Dispatch task</button>
    </form>
  )
}
