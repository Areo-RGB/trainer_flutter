import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Play, Pause, RotateCcw, Plus, Trash2, X } from 'lucide-react'
import { Card } from '../components/Card'
import { useLocalStorage } from '../hooks/useLocalStorage'

interface TimerSequence {
  id: string
  name: string
  steps: number[]
  loops: number
}

export default function Timers() {
  const navigate = useNavigate()
  const [sequences, setSequences] = useLocalStorage<TimerSequence[]>('timer_sequences', [])
  const [showBuilder, setShowBuilder] = useState(false)

  const addSequence = (seq: TimerSequence) => {
    setSequences(prev => [...prev, seq])
    setShowBuilder(false)
  }

  const deleteSequence = (id: string) => {
    setSequences(prev => prev.filter(s => s.id !== id))
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      <header className="sticky top-0 z-10 bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center gap-3">
          <button
            onClick={() => navigate('/')}
            className="p-2 -ml-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </button>
          <h1 className="text-lg font-semibold text-slate-800 dark:text-slate-200">
            Timers
          </h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {/* Custom Timer */}
          <CustomTimerCard title="Custom Timer" color="blue" defaultDuration={60} />
          
          {/* Presets */}
          <CustomTimerCard 
            title="Presets" 
            color="orange" 
            defaultDuration={30}
            presets={[15, 30, 45, 60]}
          />
          
          {/* Saved Sequences */}
          {sequences.map(seq => (
            <SequenceCard 
              key={seq.id} 
              sequence={seq} 
              onDelete={() => deleteSequence(seq.id)}
            />
          ))}
          
          {/* Add Button */}
          <Card 
            onClick={() => setShowBuilder(true)}
            className="flex flex-col items-center justify-center p-8 min-h-[280px]"
          >
            <div className="w-16 h-16 rounded-full bg-[#5076a3]/10 flex items-center justify-center mb-4">
              <Plus className="w-8 h-8 text-[#5076a3]" />
            </div>
            <div className="font-semibold text-slate-800 dark:text-slate-200">Create Sequence</div>
            <div className="text-sm text-slate-500 dark:text-slate-400">Build a custom loop of timers</div>
          </Card>
        </div>
      </main>

      {/* Builder Dialog */}
      {showBuilder && (
        <SequenceBuilderDialog
          onClose={() => setShowBuilder(false)}
          onSave={addSequence}
        />
      )}
    </div>
  )
}

function CustomTimerCard({ 
  title, 
  color, 
  defaultDuration,
  presets 
}: { 
  title: string
  color: 'blue' | 'orange'
  defaultDuration: number 
  presets?: number[]
}) {
  const [duration, setDuration] = useState(defaultDuration)
  const [remaining, setRemaining] = useState(defaultDuration)
  const [isRunning, setIsRunning] = useState(false)
  const timerRef = useRef<number | null>(null)

  useEffect(() => {
    if (isRunning) {
      timerRef.current = window.setInterval(() => {
        setRemaining(r => {
          if (r <= 1) {
            setIsRunning(false)
            return duration
          }
          return r - 1
        })
      }, 1000)
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [isRunning, duration])

  const formatTime = (sec: number) => {
    const m = Math.floor(sec / 60)
    const s = sec % 60
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }

  const start = () => {
    setRemaining(duration)
    setIsRunning(true)
  }

  const stop = () => {
    if (timerRef.current) clearInterval(timerRef.current)
    setIsRunning(false)
  }

  const reset = () => {
    stop()
    setRemaining(duration)
  }

  const colorClasses = color === 'blue' 
    ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400'
    : 'bg-orange-500/10 text-orange-600 dark:text-orange-400'

  return (
    <Card className="p-5">
      <div className={`font-semibold mb-4 ${colorClasses.split(' ').slice(1).join(' ')}`}>
        {title}
      </div>
      
      <div className="text-center text-4xl font-bold text-slate-800 dark:text-slate-200 font-mono mb-4">
        {formatTime(remaining)}
      </div>

      {presets && (
        <div className="flex flex-wrap gap-2 mb-4 justify-center">
          {presets.map(p => (
            <button
              key={p}
              onClick={() => { setDuration(p); setRemaining(p) }}
              disabled={isRunning}
              className={`px-3 py-1 rounded-full text-sm ${
                duration === p 
                  ? 'bg-[#5076a3] text-white' 
                  : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'
              } disabled:opacity-50`}
            >
              {p}s
            </button>
          ))}
        </div>
      )}

      <div className="flex justify-center gap-2">
        {!isRunning ? (
          <button
            onClick={start}
            className={`px-4 py-2 rounded-lg ${color === 'blue' ? 'bg-blue-500' : 'bg-orange-500'} text-white flex items-center gap-2`}
          >
            <Play className="w-4 h-4" /> Start
          </button>
        ) : (
          <button
            onClick={stop}
            className="px-4 py-2 rounded-lg bg-red-500 text-white flex items-center gap-2"
          >
            <Pause className="w-4 h-4" /> Stop
          </button>
        )}
        <button
          onClick={reset}
          className="p-2 rounded-lg border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
        >
          <RotateCcw className="w-4 h-4" />
        </button>
      </div>
    </Card>
  )
}

function SequenceCard({ sequence, onDelete }: { sequence: TimerSequence; onDelete: () => void }) {
  const [isRunning, setIsRunning] = useState(false)
  const [currentIndex, setCurrentIndex] = useState(0)
  const [remaining, setRemaining] = useState(0)
  const [currentLoop, setCurrentLoop] = useState(0)
  const timerRef = useRef<number | null>(null)

  useEffect(() => {
    if (isRunning) {
      timerRef.current = window.setInterval(() => {
        setRemaining(r => {
          if (r <= 1) {
            // Next step
            const nextIndex = currentIndex + 1
            if (nextIndex >= sequence.steps.length) {
              const nextLoop = currentLoop + 1
              if (sequence.loops > 0 && nextLoop >= sequence.loops) {
                setIsRunning(false)
                return 0
              }
              setCurrentLoop(nextLoop)
              setCurrentIndex(0)
              return sequence.steps[0]
            }
            setCurrentIndex(nextIndex)
            return sequence.steps[nextIndex]
          }
          return r - 1
        })
      }, 1000)
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [isRunning, currentIndex, currentLoop, sequence])

  const start = () => {
    setCurrentIndex(0)
    setCurrentLoop(0)
    setRemaining(sequence.steps[0])
    setIsRunning(true)
  }

  const stop = () => {
    if (timerRef.current) clearInterval(timerRef.current)
    setIsRunning(false)
  }

  return (
    <Card className="p-5">
      <div className="flex justify-between items-start mb-2">
        <div className="font-semibold text-slate-800 dark:text-slate-200">{sequence.name}</div>
        <button onClick={onDelete} className="text-red-500 hover:text-red-600">
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
      <div className="text-sm text-slate-500 dark:text-slate-400 mb-4">
        {sequence.steps.length} steps • {sequence.loops > 0 ? `${sequence.loops} loops` : 'infinite'}
      </div>

      {isRunning && (
        <div className="text-center mb-4">
          <div className="text-sm text-slate-500 dark:text-slate-400">
            Step {currentIndex + 1}/{sequence.steps.length}
          </div>
          <div className="text-3xl font-bold text-slate-800 dark:text-slate-200">
            {remaining}s
          </div>
        </div>
      )}

      <div className="flex justify-center">
        <button
          onClick={isRunning ? stop : start}
          className={`px-4 py-2 rounded-lg ${isRunning ? 'bg-red-500' : 'bg-[#5076a3]'} text-white flex items-center gap-2`}
        >
          {isRunning ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
          {isRunning ? 'Stop' : 'Start'}
        </button>
      </div>
    </Card>
  )
}

function SequenceBuilderDialog({ onClose, onSave }: { onClose: () => void; onSave: (seq: TimerSequence) => void }) {
  const [name, setName] = useState('')
  const [steps, setSteps] = useState([30])
  const [loops, setLoops] = useState(0)

  const addStep = () => setSteps(s => [...s, 30])
  const removeStep = (i: number) => {
    if (steps.length > 1) setSteps(s => s.filter((_, idx) => idx !== i))
  }
  const updateStep = (i: number, val: number) => {
    setSteps(s => s.map((v, idx) => idx === i ? val : v))
  }

  const save = () => {
    if (!name.trim()) return
    onSave({
      id: Date.now().toString(),
      name: name.trim(),
      steps,
      loops,
    })
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <Card className="w-full max-w-md p-6 max-h-[90vh] overflow-auto">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold text-slate-800 dark:text-slate-200">New Sequence</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
              Sequence Name
            </label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200"
              placeholder="Enter name..."
            />
          </div>

          <div>
            <label className="block text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 mb-2 uppercase">
              Steps
            </label>
            {steps.map((step, i) => (
              <div key={i} className="flex gap-2 mb-2">
                <span className="text-slate-600 dark:text-slate-400 py-2">Step {i + 1}</span>
                <input
                  type="number"
                  value={step}
                  onChange={e => updateStep(i, Number(e.target.value))}
                  className="flex-1 px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200"
                />
                <span className="text-slate-500 dark:text-slate-400 py-2">sec</span>
                <button
                  onClick={() => removeStep(i)}
                  className="text-slate-400 hover:text-red-500"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            ))}
            <button
              onClick={addStep}
              className="text-[#5076a3] hover:text-[#3a5a7c] flex items-center gap-1 text-sm"
            >
              <Plus className="w-4 h-4" /> Add Step
            </button>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
              Loops (0 = infinite)
            </label>
            <input
              type="number"
              value={loops}
              onChange={e => setLoops(Number(e.target.value))}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200"
            />
          </div>

          <button
            onClick={save}
            disabled={!name.trim()}
            className="w-full py-3 rounded-xl bg-[#5076a3] hover:bg-[#3a5a7c] disabled:bg-slate-400 text-white font-semibold transition-colors"
          >
            Save Sequence
          </button>
        </div>
      </Card>
    </div>
  )
}
