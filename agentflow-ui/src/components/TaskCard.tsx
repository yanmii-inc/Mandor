import React from 'react'
import StatusPill from './StatusPill'
import type { Task } from '../types'
import { Link } from 'react-router-dom'

export default function TaskCard({ task }: { task: Task }) {
  return (
    <Link to={`/tasks/${task.id}`} className="block p-4 bg-gray-800 rounded-lg mb-3">
      <div className="flex justify-between items-start">
        <div className="text-sm font-semibold">{task.description.slice(0, 80)}{task.description.length>80?'...':''}</div>
        <StatusPill status={task.status} />
      </div>
      <div className="text-xs text-gray-400 mt-2">{task.branch || 'main'} · {task.token_usage ? `${task.token_usage.total} tokens` : ''}</div>
    </Link>
  )
}
