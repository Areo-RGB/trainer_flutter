import type { ReactNode } from 'react'

interface CardProps {
  children: ReactNode
  className?: string
  onClick?: () => void
}

export function Card({ children, className = '', onClick }: CardProps) {
  return (
    <div
      onClick={onClick}
      className={`
        bg-white dark:bg-slate-800 
        rounded-2xl shadow-sm 
        border border-slate-200 dark:border-slate-700
        ${onClick ? 'cursor-pointer hover:shadow-md hover:border-slate-300 dark:hover:border-slate-600 transition-all' : ''}
        ${className}
      `}
    >
      {children}
    </div>
  )
}

interface ConfigCardProps {
  title: string
  children: ReactNode
  className?: string
}

export function ConfigCard({ title, children, className = '' }: ConfigCardProps) {
  return (
    <div className={`bg-slate-100 dark:bg-slate-800/50 rounded-xl p-5 ${className}`}>
      <div className="text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 mb-4 uppercase">
        {title}
      </div>
      {children}
    </div>
  )
}
