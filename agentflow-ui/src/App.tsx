import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import Home from './screens/Home'
import TaskDetail from './screens/TaskDetail'
import NewTask from './screens/NewTask'
import Projects from './screens/Projects'
import Profiles from './screens/Profiles'
import Tokens from './screens/Tokens'
import Setup from './screens/Setup'

export default function App() {
  const apiBase = localStorage.getItem('api_base')
  const token = localStorage.getItem('auth_token')
  if (!apiBase || !token) {
    return <Navigate to="/setup" replace />
  }

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/setup" element={<Setup />} />
        <Route path="/tasks/new" element={<NewTask />} />
        <Route path="/tasks/:id" element={<TaskDetail />} />
        <Route path="/projects" element={<Projects />} />
        <Route path="/profiles" element={<Profiles />} />
        <Route path="/tokens" element={<Tokens />} />
      </Routes>
    </div>
  )
}
