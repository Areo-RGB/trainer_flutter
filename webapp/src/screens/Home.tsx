import { useNavigate } from 'react-router-dom'
import { 
  Palette, 
  Calculator, 
  Timer, 
  Bell, 
  Mic, 
  Video,
  LayoutGrid
} from 'lucide-react'
import { Card } from '../components/Card'

interface Tool {
  title: string
  description: string
  route: string
  icon: React.ReactNode
  color: string
}

const tools: Tool[] = [
  {
    title: 'Farben',
    description: 'Stroop effect trainer. Flashes colors and words.',
    route: '/farben',
    icon: <Palette className="w-6 h-6" />,
    color: 'bg-pink-500',
  },
  {
    title: 'Kettenrechner',
    description: 'Mental math chain calculator. Solve operations.',
    route: '/kettenrechner',
    icon: <Calculator className="w-6 h-6" />,
    color: 'bg-blue-500',
  },
  {
    title: 'Timers',
    description: 'Interval timers and loop presets for training.',
    route: '/timers',
    icon: <Timer className="w-6 h-6" />,
    color: 'bg-orange-500',
  },
  {
    title: 'Intervall',
    description: 'Set custom intervals for audio beep reminders.',
    route: '/intervall',
    icon: <Bell className="w-6 h-6" />,
    color: 'bg-green-500',
  },
  {
    title: 'Sound Counter',
    description: 'Count sounds using microphone threshold detection.',
    route: '/sound-counter',
    icon: <Mic className="w-6 h-6" />,
    color: 'bg-purple-500',
  },
  {
    title: 'Motion Counter',
    description: 'Count motion crossings using camera tripwire.',
    route: '/motion-counter',
    icon: <Video className="w-6 h-6" />,
    color: 'bg-cyan-500',
  },
]

export default function Home() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      {/* App Bar */}
      <header className="sticky top-0 z-10 bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center gap-3">
          <div className="p-2 rounded-lg bg-[#5076a3]/10">
            <LayoutGrid className="w-5 h-5 text-[#5076a3]" />
          </div>
          <h1 className="text-lg font-semibold text-slate-800 dark:text-slate-200">
            Training
          </h1>
        </div>
      </header>

      {/* Grid */}
      <main className="max-w-4xl mx-auto p-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {tools.map((tool) => (
            <Card
              key={tool.route}
              onClick={() => navigate(tool.route)}
              className="p-5"
            >
              <div className="flex items-start gap-4">
                <div className={`${tool.color} text-white p-3 rounded-xl`}>
                  {tool.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <h2 className="font-semibold text-slate-800 dark:text-slate-200 mb-1">
                    {tool.title}
                  </h2>
                  <p className="text-sm text-slate-500 dark:text-slate-400 line-clamp-2">
                    {tool.description}
                  </p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </main>
    </div>
  )
}
