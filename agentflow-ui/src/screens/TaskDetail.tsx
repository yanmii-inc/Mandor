import React, { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { apiClient } from '../api/client'
import TaskThread from '../components/TaskThread'
import FollowUpInput from '../components/FollowUpInput'
import PreflightCard from '../components/PreflightCard'
import { useTaskStream } from '../hooks/useTaskStream'
import StatusPill from '../components/StatusPill'

export default function TaskDetail() {
  const { id } = useParams()
  const [task, setTask] = useState<any | null>(null)
  const { logs, isStreaming } = useTaskStream(id, task?.status==='running')
  useEffect(() => { if (!id) return; apiClient.getTask(id).then(setTask) }, [id])
  if (!task) return <div className="p-4">Loading...</div>

  return (
    <div className="p-4 pb-40">
      <div className="flex items-center gap-3 mb-4">
        <Link to="/" className="text-sm">← Back</Link>
        <div className="flex-1">
          <div className="font-semibold">{task.project_id}</div>
          <div className="text-xs text-gray-400">{task.branch || 'main'}</div>
        </div>
        <StatusPill status={task.status} />
        {task.pr_url && <a href={task.pr_url} target="_blank" rel="noreferrer" className="ml-2 text-sm">Open PR</a>}
      </div>

      {task.status === 'pending' && (
        <PreflightCard complexity="Unknown" estimate="—" onConfirm={() => apiClient.confirmTask(task.id).then(()=>apiClient.getTask(task.id).then(setTask))} onEdit={()=>{ window.location.href='/tasks/new?edit='+task.description }} />
      )}

      <TaskThread logs={logs} />

      {task.status === 'running' && (
        <FollowUpInput onSend={async (msg) => { await apiClient.replyTask(task.id, msg) }} />
      )}

    </div>
  )
}
