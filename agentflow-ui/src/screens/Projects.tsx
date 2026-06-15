import React, { useEffect, useState } from 'react'
import { apiClient } from '../api/client'
export default function Projects() {
  const [projects, setProjects] = useState<any[]>([])
  useEffect(()=>{ apiClient.getProjects().then(setProjects) },[])
  return (
    <div className="p-4">
      <h2 className="text-lg font-semibold mb-3">Projects</h2>
      {projects.map(p=> <div key={p.id} className="p-2 bg-gray-800 rounded mb-2">{p.name} <div className="text-xs text-gray-500">{p.repo_url}</div></div>)}
    </div>
  )
}
