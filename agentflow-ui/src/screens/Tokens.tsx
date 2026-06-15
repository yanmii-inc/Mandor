import React, { useEffect, useState } from 'react'
import { apiClient } from '../api/client'
export default function Tokens() {
  const [tokens, setTokens] = useState<any | null>(null)
  useEffect(()=>{ apiClient.getTokens().then(setTokens) },[])
  if (!tokens) return <div className="p-4">Loading...</div>
  return (
    <div className="p-4">
      <h2 className="text-lg font-semibold">Tokens</h2>
      <div className="mt-2">
        <div>Input: {tokens.total_input}</div>
        <div>Output: {tokens.total_output}</div>
        <div>Total: {tokens.total_tokens}</div>
        <div>Tasks: {tokens.task_count}</div>
      </div>
    </div>
  )
}
