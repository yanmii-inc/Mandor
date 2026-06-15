import React, { useState } from 'react'

export default function FollowUpInput({ onSend }: { onSend: (msg: string) => Promise<void> }) {
  const [text, setText] = useState('')
  const [busy, setBusy] = useState(false)
  const send = async () => {
    if (!text.trim()) return
    setBusy(true)
    try { await onSend(text.trim()); setText('') } finally { setBusy(false) }
  }
  return (
    <div className="p-3 bg-gray-900 border-t border-gray-800 fixed bottom-0 left-0 right-0">
      <div className="flex gap-2">
        <textarea rows={2} value={text} onChange={(e)=>setText(e.target.value)} className="flex-1 bg-gray-800 p-2 rounded text-sm" />
        <button onClick={send} disabled={busy} className="bg-indigo-600 px-4 rounded text-sm">{busy?'...':'Send'}</button>
      </div>
    </div>
  )
}
