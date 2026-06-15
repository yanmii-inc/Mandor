import React from 'react'

export default function PreflightCard({ complexity, estimate, onConfirm, onEdit }: {complexity:string, estimate:string, onConfirm:()=>void, onEdit:()=>void}) {
  return (
    <div className="p-4 bg-gray-800 rounded m-4">
      <div className="text-sm">Complexity: {complexity}</div>
      <div className="text-sm">Estimated tokens: {estimate}</div>
      <div className="mt-3 flex gap-2">
        <button onClick={onConfirm} className="bg-green-600 px-3 py-1 rounded">Confirm</button>
        <button onClick={onEdit} className="bg-gray-600 px-3 py-1 rounded">Edit</button>
      </div>
    </div>
  )
}
