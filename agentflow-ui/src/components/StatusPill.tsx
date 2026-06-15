import React from 'react'

type Props = { status: string }
export default function StatusPill({ status }: Props) {
  const map: Record<string,string> = {
    pending: 'bg-gray-600 text-white',
    running: 'bg-blue-500 text-white animate-pulse',
    pr_ready: 'bg-yellow-500 text-black',
    merged: 'bg-green-600 text-white',
    failed: 'bg-red-600 text-white',
  }
  const cls = map[status] || 'bg-gray-600'
  return <span className={`px-2 py-1 rounded-full text-xs ${cls}`}>{status}</span>
}
