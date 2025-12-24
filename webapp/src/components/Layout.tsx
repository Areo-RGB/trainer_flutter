import { useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import type { ReactNode } from 'react'

interface LayoutProps {
  title: string
  children: ReactNode
  actions?: ReactNode
  hideBackButton?: boolean
}

export function Layout({ title, children, actions, hideBackButton = false }: LayoutProps) {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* App Bar */}
      <header className="sticky top-0 z-10 bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center gap-3">
          {!hideBackButton && (
            <button
              onClick={() => navigate('/')}
              className="p-2 -ml-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
            >
              <ArrowLeft className="w-5 h-5 text-slate-600 dark:text-slate-400" />
            </button>
          )}
          <h1 className="text-lg font-semibold text-slate-800 dark:text-slate-200 flex-1">
            {title}
          </h1>
          {actions}
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto p-4">
        {children}
      </main>
    </div>
  )
}
