import React, { useEffect, useState } from 'react'
import { apiClient } from '../api/client'
import TaskCard from '../components/TaskCard'
import { Link } from 'react-router-dom'

export default function Home() {
  const [tasks, setTasks] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    let mounted = true
    apiClient.getTasks().then((t) => { if (mounted) setTasks(t) }).finally(()=>mounted && setLoading(false))
    return ()=>{ mounted = false }
  }, [])
  const runningCount = tasks.filter(t=>t.status==='running').length
  return (
    <div className="p-4 pb-24">
      <header className="flex justify-between items-center mb-4">
        <h1 className="text-xl font-bold">agentflow</h1>
        <div className="flex items-center gap-3">
          <Link to="/projects" className="text-sm">Projects</Link>
          <Link to="/profiles" className="text-sm">Profiles</Link>
          <Link to="/tokens" className="text-sm">Tokens</Link>
        </div>
      </header>

      {loading ? <div>Loading...</div> : (
        tasks.length === 0 ? (
          <div className="text-center mt-16">
            <p className="text-gray-400">No tasks yet. Tap + to dispatch your first task.</p>
          </div>
        ) : (
          <div>
            {tasks.map((t)=> <TaskCard key={t.id} task={t} />)}
          </div>
        )
      )}

      <Link to="/tasks/new" className="fixed right-4 bottom-16 bg-indigo-600 w-14 h-14 rounded-full flex items-center justify-center text-white text-2xl">+</Link>
      <nav className="fixed bottom-0 left-0 right-0 bg-gray-900 border-t border-gray-800 p-2 flex justify-around">
        <div className="flex flex-col items-center text-sm"><span>🏠</span><span>Home</span></div>
        <Link to="/projects" className="flex flex-col items-center text-sm"><span>📁</span><span>Projects</span></Link>
        <Link to="/profiles" className="flex flex-col items-center text-sm"><span>🤖</span><span>Profiles</span></Link>
        <Link to="/tokens" className="flex flex-col items-center text-sm"><span>📊</span><span>Tokens</span></Link>
      </nav>
    </div>
  )
}
