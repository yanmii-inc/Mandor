import React, { useEffect, useState } from 'react'
import { apiClient } from '../api/client'
export default function Profiles() {
  const [profiles, setProfiles] = useState<any[]>([])
  useEffect(()=>{ apiClient.getAgentProfiles().then(setProfiles) },[])
  return (
    <div className="p-4">
      <h2 className="text-lg font-semibold mb-3">Agent Profiles</h2>
      {profiles.map(p=> <div key={p.id} className="p-2 bg-gray-800 rounded mb-2">{p.name} — {p.agent_type}</div>)}
    </div>
  )
}
