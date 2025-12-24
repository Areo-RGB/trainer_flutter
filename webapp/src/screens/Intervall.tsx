import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Play, Pause, Volume2 } from 'lucide-react'
import { Card, ConfigCard } from '../components/Card'
import { useAudio } from '../hooks/useAudio'

export default function Intervall() {
  const navigate = useNavigate()
  const { playBeep } = useAudio()
  
  const [intervalSec, setIntervalSec] = useState(2)
  const [limitSec, setLimitSec] = useState('')
  const [volumeBoost, setVolumeBoost] = useState(false)
  const [isRunning, setIsRunning] = useState(false)
  const [remaining, setRemaining] = useState(2)
  
  const beepTimerRef = useRef<number | null>(null)
  const limitTimerRef = useRef<number | null>(null)

  useEffect(() => {
    if (isRunning) {
      beepTimerRef.current = window.setInterval(() => {
        setRemaining(r => {
          if (r <= 1) {
            playBeep(volumeBoost ? 0.8 : 0.3)
            return intervalSec
          }
          return r - 1
        })
      }, 1000)
    }
    return () => {
      if (beepTimerRef.current) clearInterval(beepTimerRef.current)
    }
  }, [isRunning, intervalSec, volumeBoost, playBeep])

  const start = () => {
    setRemaining(intervalSec)
    setIsRunning(true)
    playBeep(volumeBoost ? 0.8 : 0.3)
    
    const limit = parseInt(limitSec, 10)
    if (!isNaN(limit) && limit > 0) {
      limitTimerRef.current = window.setTimeout(stop, limit * 1000)
    }
  }

  const stop = () => {
    if (beepTimerRef.current) clearInterval(beepTimerRef.current)
    if (limitTimerRef.current) clearTimeout(limitTimerRef.current)
    setIsRunning(false)
    setRemaining(intervalSec)
  }

  const toggle = () => (isRunning ? stop() : start())

  const presets = [2, 5, 10, 30]

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
            Intervall
          </h1>
        </div>
      </header>

      <main className="max-w-md mx-auto p-6">
        <Card className="p-6">
          {/* Timer Display */}
          <div className="flex justify-center mb-6">
            <div className={`w-36 h-36 rounded-full flex items-center justify-center ${
              isRunning ? 'bg-[#5076a3]/20' : 'bg-slate-200 dark:bg-slate-700'
            }`}>
              {isRunning ? (
                <span className="text-4xl font-bold text-[#5076a3]">{remaining}s</span>
              ) : (
                <div className="w-12 h-12 text-slate-400">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M23 4v6h-6M1 20v-6h6" />
                    <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
                  </svg>
                </div>
              )}
            </div>
          </div>

          <h2 className="text-center text-xl font-bold text-slate-800 dark:text-slate-200 mb-2">
            Intervall
          </h2>
          <p className="text-center text-slate-500 dark:text-slate-400 text-sm mb-6">
            Periodic audio cues for training.
          </p>

          {/* Interval Control */}
          <ConfigCard title="INTERVAL (SECONDS)" className="mb-4">
            <div className="flex items-center justify-center gap-3">
              <button
                onClick={() => setIntervalSec(v => Math.max(0.5, v - 0.5))}
                disabled={isRunning}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center disabled:opacity-50"
              >
                -
              </button>
              <input
                type="number"
                value={intervalSec}
                onChange={e => setIntervalSec(Number(e.target.value))}
                disabled={isRunning}
                className="w-20 text-center text-xl font-bold py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 disabled:opacity-50"
                step={0.5}
                min={0.5}
                max={60}
              />
              <button
                onClick={() => setIntervalSec(v => Math.min(60, v + 0.5))}
                disabled={isRunning}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center disabled:opacity-50"
              >
                +
              </button>
            </div>
            <div className="flex flex-wrap gap-2 justify-center mt-3">
              {presets.map(p => (
                <button
                  key={p}
                  onClick={() => { setIntervalSec(p); setRemaining(p) }}
                  disabled={isRunning}
                  className={`px-3 py-1 rounded-full text-sm ${
                    intervalSec === p 
                      ? 'bg-[#5076a3] text-white' 
                      : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'
                  } disabled:opacity-50`}
                >
                  {p}s
                </button>
              ))}
            </div>
          </ConfigCard>

          {/* Auto-stop Limit */}
          <ConfigCard title="AUTO-STOP LIMIT" className="mb-4">
            <input
              type="number"
              value={limitSec}
              onChange={e => setLimitSec(e.target.value)}
              disabled={isRunning}
              placeholder="Optional (e.g. 60)"
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 disabled:opacity-50"
            />
            <div className="text-right text-xs text-slate-500 dark:text-slate-400 mt-1">seconds</div>
          </ConfigCard>

          {/* Volume Boost */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-slate-100 dark:bg-slate-800 mb-6">
            <div className="flex items-center gap-3">
              <Volume2 className="w-5 h-5 text-[#5076a3]" />
              <span className="text-slate-700 dark:text-slate-300">Volume Boost</span>
            </div>
            <input
              type="checkbox"
              checked={volumeBoost}
              onChange={e => setVolumeBoost(e.target.checked)}
              className="w-5 h-5 accent-[#5076a3]"
            />
          </div>

          {/* Start/Stop Button */}
          <button
            onClick={toggle}
            className={`w-full py-4 rounded-xl font-semibold text-lg flex items-center justify-center gap-2 transition-colors ${
              isRunning 
                ? 'bg-red-500 hover:bg-red-600 text-white' 
                : 'bg-[#5076a3] hover:bg-[#3a5a7c] text-white'
            }`}
          >
            {isRunning ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5" />}
            {isRunning ? 'Stop' : 'Start Timer'}
          </button>
        </Card>
      </main>
    </div>
  )
}
