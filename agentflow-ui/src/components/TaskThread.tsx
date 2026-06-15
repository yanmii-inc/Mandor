import React, { useEffect, useRef } from 'react'
import type { TaskLog } from '../types'

export default function TaskThread({ logs }: { logs: TaskLog[] }) {
  const bottomRef = useRef<HTMLDivElement | null>(null)
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }) }, [logs.length])
  return (
    <div className="space-y-2 p-4">
      {logs.map((l) => (
        <div key={l.id} className={l.role === 'user' ? 'text-right' : 'text-left'}>
          <div className={`inline-block p-2 rounded ${l.role === 'user' ? 'bg-indigo-600' : 'bg-gray-800'} font-mono text-sm`}>
            {l.chunk}
          </div>
          <div className="text-xs text-gray-500 mt-1">{new Date(l.timestamp).toLocaleTimeString()}</div>
        </div>
      ))}
      <div ref={bottomRef} />
    </div>
  )
}
