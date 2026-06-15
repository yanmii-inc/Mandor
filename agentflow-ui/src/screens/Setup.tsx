import React, { useState } from 'react'

export default function Setup() {
  const [base, setBase] = useState(localStorage.getItem('api_base') || 'http://localhost:3000')
  const [token, setToken] = useState(localStorage.getItem('auth_token') || '')
  const [testing, setTesting] = useState(false)
  const test = async () => {
    setTesting(true)
    try {
      const res = await fetch(`${base}/projects`, { headers: { 'Authorization': `Bearer ${token}` } })
      if (res.ok) {
        localStorage.setItem('api_base', base)
        localStorage.setItem('auth_token', token)
        window.location.href = '/'
      } else {
        alert('Connection failed: '+res.statusText)
      }
    } catch (err) {
      alert('Connection failed')
    } finally { setTesting(false) }
  }
  return (
    <div className="p-4">
      <h2 className="text-lg font-semibold mb-2">Setup</h2>
      <label className="text-xs text-gray-400">API base URL</label>
      <input value={base} onChange={(e)=>setBase(e.target.value)} className="w-full p-2 bg-gray-800 mb-3" />
      <label className="text-xs text-gray-400">Auth token</label>
      <input value={token} onChange={(e)=>setToken(e.target.value)} className="w-full p-2 bg-gray-800 mb-3" />
      <button onClick={test} className="w-full py-3 bg-indigo-600 rounded">{testing ? 'Connecting...' : 'Connect'}</button>
    </div>
  )
}
