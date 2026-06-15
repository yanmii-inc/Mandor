import { useEffect, useRef, useState } from 'react'
import type { TaskLog } from '../types'

export function useTaskStream(taskId?: string, enabled = false) {
  const [logs, setLogs] = useState<TaskLog[]>([])
  const [isStreaming, setIsStreaming] = useState(false)
  const sourceRef = useRef<EventSource | null>(null)

  useEffect(() => {
    if (!enabled || !taskId) return
    const base = localStorage.getItem('api_base') || 'http://localhost:3000'
    const url = `${base}/tasks/${taskId}/logs`
    const source = new EventSource(url)
    sourceRef.current = source
    setIsStreaming(true)

    source.addEventListener('log', (e: MessageEvent) => {
      try {
        const chunk = JSON.parse(e.data) as TaskLog
        setLogs((s) => [...s, chunk])
      } catch (err) {
        console.error('parse log', err)
      }
    })

    source.addEventListener('done', () => {
      setIsStreaming(false)
      source.close()
    })

    source.addEventListener('error', (e) => {
      console.error('SSE error', e)
      setIsStreaming(false)
      source.close()
    })

    return () => {
      setIsStreaming(false)
      source.close()
    }
  }, [taskId, enabled])

  const close = () => {
    sourceRef.current?.close()
    sourceRef.current = null
    setIsStreaming(false)
  }

  return { logs, isStreaming, close }
}
