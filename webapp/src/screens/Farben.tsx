import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Settings, Pause, Play, X } from 'lucide-react'
import { ConfigCard } from '../components/Card'
import { useAudio } from '../hooks/useAudio'

type ColorType = 'red' | 'green' | 'blue' | 'yellow' | 'orange' | 'purple' | 'white'

const colorConfigs: Record<ColorType, { bg: string; text: string; label: string }> = {
  red: { bg: 'bg-red-700', text: 'text-white', label: 'ROT' },
  green: { bg: 'bg-green-700', text: 'text-white', label: 'GRÜN' },
  blue: { bg: 'bg-blue-700', text: 'text-white', label: 'BLAU' },
  yellow: { bg: 'bg-yellow-500', text: 'text-black', label: 'GELB' },
  orange: { bg: 'bg-orange-600', text: 'text-white', label: 'ORANGE' },
  purple: { bg: 'bg-purple-700', text: 'text-white', label: 'LILA' },
  white: { bg: 'bg-white', text: 'text-black', label: 'WEISS' },
}

const colorTypes: ColorType[] = ['red', 'green', 'blue', 'yellow', 'orange', 'purple', 'white']

export default function Farben() {
  const navigate = useNavigate()
  const { playBeep } = useAudio()
  
  // Config state
  const [intervalMs, setIntervalMs] = useState(1000)
  const [noColors, setNoColors] = useState(false)
  const [preventDuplicates, setPreventDuplicates] = useState(false)
  const [playSoundOnChange, setPlaySoundOnChange] = useState(false)
  const [customLabels, setCustomLabels] = useState<string[]>([''])
  
  // Game state
  const [isPlaying, setIsPlaying] = useState(false)
  const [isPaused, setIsPaused] = useState(false)
  const [currentColor, setCurrentColor] = useState<ColorType>('white')
  const [currentLabel, setCurrentLabel] = useState('')
  
  const timerRef = useRef<number | null>(null)
  const prevColorRef = useRef<ColorType>('white')
  const prevLabelRef = useRef('')

  const getNextColor = useCallback((prev: ColorType): ColorType => {
    const available = colorTypes.filter(c => c !== prev)
    return available[Math.floor(Math.random() * available.length)]
  }, [])

  const getNextLabel = useCallback((prev: string): string => {
    const validLabels = customLabels.filter(l => l.trim())
    if (validLabels.length === 0) return ''
    
    let pool = validLabels
    if (preventDuplicates && prev && validLabels.length > 1) {
      pool = validLabels.filter(l => l !== prev)
    }
    return pool[Math.floor(Math.random() * pool.length)]
  }, [customLabels, preventDuplicates])

  const tick = useCallback(() => {
    const nextColor = getNextColor(prevColorRef.current)
    const nextLabel = getNextLabel(prevLabelRef.current)
    
    prevColorRef.current = nextColor
    prevLabelRef.current = nextLabel
    
    setCurrentColor(nextColor)
    setCurrentLabel(nextLabel)
    
    if (playSoundOnChange) {
      playBeep(0.3)
    }
  }, [getNextColor, getNextLabel, playSoundOnChange, playBeep])

  const startGame = useCallback(() => {
    setIsPlaying(true)
    setIsPaused(false)
    tick()
  }, [tick])

  useEffect(() => {
    if (isPlaying && !isPaused) {
      timerRef.current = window.setInterval(tick, intervalMs)
    }
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current)
      }
    }
  }, [isPlaying, isPaused, intervalMs, tick])

  const stopGame = () => {
    if (timerRef.current) clearInterval(timerRef.current)
    setIsPlaying(false)
    setIsPaused(false)
  }

  const handleLabelChange = (index: number, value: string) => {
    setCustomLabels(prev => {
      const updated = [...prev]
      updated[index] = value
      if (index === prev.length - 1 && value.trim()) {
        updated.push('')
      }
      return updated
    })
  }

  const removeLabel = (index: number) => {
    setCustomLabels(prev => {
      const updated = prev.filter((_, i) => i !== index)
      return updated.length === 0 ? [''] : updated
    })
  }

  // Playing mode
  if (isPlaying) {
    const config = colorConfigs[currentColor]
    const bgColor = noColors ? 'bg-gray-900' : config.bg
    const textColor = noColors ? 'text-white' : config.text
    const displayLabel = currentLabel || config.label

    return (
      <div className={`min-h-screen ${bgColor} flex items-center justify-center relative`}>
        <h1 className={`text-7xl md:text-9xl font-bold ${textColor}`}>
          {displayLabel}
        </h1>

        {/* Controls */}
        <div className="absolute top-4 left-4">
          <button
            onClick={() => navigate('/')}
            className="p-3 rounded-xl bg-white/20 hover:bg-white/30 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
        </div>
        <div className="absolute top-4 right-4 flex gap-2">
          <button
            onClick={stopGame}
            className="p-3 rounded-xl bg-white/20 hover:bg-white/30 transition-colors"
          >
            <Settings className="w-5 h-5 text-white" />
          </button>
          <button
            onClick={() => setIsPaused(p => !p)}
            className="p-3 rounded-xl bg-white/20 hover:bg-white/30 transition-colors"
          >
            {isPaused ? (
              <Play className="w-5 h-5 text-white" />
            ) : (
              <Pause className="w-5 h-5 text-white" />
            )}
          </button>
        </div>
      </div>
    )
  }

  // Config mode
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
            Farben
          </h1>
        </div>
      </header>

      <main className="max-w-md mx-auto p-6 space-y-4">
        {/* Interval */}
        <ConfigCard title="INTERVAL (MS)">
          <div className="flex items-center justify-center gap-4">
            <button
              onClick={() => setIntervalMs(v => Math.max(100, v - 100))}
              className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
            >
              -
            </button>
            <span className="text-2xl font-bold text-slate-800 dark:text-slate-200 w-28 text-center">
              {intervalMs}ms
            </span>
            <button
              onClick={() => setIntervalMs(v => Math.min(5000, v + 100))}
              className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
            >
              +
            </button>
          </div>
        </ConfigCard>

        {/* Options */}
        <ConfigCard title="OPTIONS">
          <div className="space-y-3">
            <label className="flex items-center justify-between">
              <span className="text-slate-700 dark:text-slate-300">No Colors (Text Only)</span>
              <input
                type="checkbox"
                checked={noColors}
                onChange={e => setNoColors(e.target.checked)}
                className="w-5 h-5 accent-[#5076a3]"
              />
            </label>
            <label className="flex items-center justify-between">
              <span className="text-slate-700 dark:text-slate-300">Prevent Duplicate Words</span>
              <input
                type="checkbox"
                checked={preventDuplicates}
                onChange={e => setPreventDuplicates(e.target.checked)}
                className="w-5 h-5 accent-[#5076a3]"
              />
            </label>
            <label className="flex items-center justify-between">
              <span className="text-slate-700 dark:text-slate-300">Play Sound on Change</span>
              <input
                type="checkbox"
                checked={playSoundOnChange}
                onChange={e => setPlaySoundOnChange(e.target.checked)}
                className="w-5 h-5 accent-[#5076a3]"
              />
            </label>
          </div>
        </ConfigCard>

        {/* Custom Labels */}
        <ConfigCard title="CUSTOM LABELS">
          <div className="space-y-2">
            {customLabels.map((label, i) => (
              <div key={i} className="flex gap-2">
                <input
                  type="text"
                  value={label}
                  onChange={e => handleLabelChange(i, e.target.value)}
                  placeholder="Enter label..."
                  className="flex-1 px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200"
                />
                {customLabels.length > 1 && (
                  <button
                    onClick={() => removeLabel(i)}
                    className="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
                  >
                    <X className="w-5 h-5" />
                  </button>
                )}
              </div>
            ))}
          </div>
        </ConfigCard>

        {/* Start Button */}
        <button
          onClick={startGame}
          className="w-full py-4 rounded-xl bg-[#5076a3] hover:bg-[#3a5a7c] text-white font-semibold text-lg transition-colors"
        >
          Start
        </button>
      </main>
    </div>
  )
}
