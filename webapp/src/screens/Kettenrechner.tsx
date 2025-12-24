import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Delete, Check, RotateCcw, Trophy } from 'lucide-react'
import { ConfigCard } from '../components/Card'
import { useLocalStorage } from '../hooks/useLocalStorage'

type GameStatus = 'config' | 'playing' | 'pending' | 'result'

export default function Kettenrechner() {
  const navigate = useNavigate()
  
  // Config (persisted)
  const [speed, setSpeed] = useLocalStorage('kettenrechner_speed', 5)
  const [targetSteps, setTargetSteps] = useLocalStorage('kettenrechner_steps', 5)
  const [fontSize, setFontSize] = useLocalStorage('kettenrechner_fontSize', 6)
  
  // Game state
  const [status, setStatus] = useState<GameStatus>('config')
  const [display, setDisplay] = useState('Ready?')
  const [total, setTotal] = useState(0)
  const [history, setHistory] = useState<string[]>([])
  const [currentStep, setCurrentStep] = useState(0)
  const [userAnswer, setUserAnswer] = useState('')
  const [isCorrect, setIsCorrect] = useState<boolean | null>(null)
  
  const timerRef = useRef<number | null>(null)
  const lastOpRef = useRef<string | null>(null)

  const clearTimers = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current)
      timerRef.current = null
    }
  }, [])

  useEffect(() => {
    return clearTimers
  }, [clearTimers])

  const startGame = () => {
    clearTimers()
    setStatus('playing')
    setTotal(0)
    setHistory([])
    setCurrentStep(0)
    lastOpRef.current = null
    
    // Countdown
    const seq = ['3', '2', '1']
    let idx = 0
    setDisplay(seq[0])
    
    timerRef.current = window.setInterval(() => {
      idx++
      if (idx < seq.length) {
        setDisplay(seq[idx])
      } else {
        clearTimers()
        runGameLogic()
      }
    }, 1000)
  }

  const runGameLogic = () => {
    let steps = 0
    let runningTotal = 0

    const tick = () => {
      if (targetSteps > 0 && steps >= targetSteps) {
        finishGame()
        return
      }

      let n: number
      let add: boolean
      let opStr: string
      let attempts = 0

      do {
        n = Math.floor(Math.random() * 9) + 1
        add = Math.random() > 0.5
        if (!add && runningTotal - n < 0) add = true
        opStr = add ? `+${n}` : `-${n}`
        attempts++
      } while (opStr === lastOpRef.current && attempts < 10)

      lastOpRef.current = opStr
      runningTotal = add ? runningTotal + n : runningTotal - n
      
      setTotal(runningTotal)
      setDisplay(opStr)
      setHistory(h => [...h, opStr])
      setCurrentStep(s => s + 1)
      steps++
    }

    tick()
    timerRef.current = window.setInterval(tick, speed * 1000)
  }

  const finishGame = () => {
    clearTimers()
    setStatus('pending')
    setDisplay('?')
    setUserAnswer('')
    setIsCorrect(null)
  }

  const appendDigit = (digit: string) => {
    if (digit === '-' && userAnswer.length === 0) {
      setUserAnswer('-')
    } else if (digit !== '-') {
      setUserAnswer(prev => prev + digit)
    }
  }

  const clearInput = () => setUserAnswer('')

  const checkAnswer = () => {
    const parsed = parseInt(userAnswer, 10)
    const correct = !isNaN(parsed) && parsed === total
    setIsCorrect(correct)
    setStatus('result')
  }

  const returnToConfig = () => {
    clearTimers()
    setStatus('config')
    setDisplay('Ready?')
  }

  // Config screen
  if (status === 'config') {
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
              Kettenrechner
            </h1>
          </div>
        </header>

        <main className="max-w-md mx-auto p-6 space-y-4">
          {/* Speed */}
          <ConfigCard title="SPEED (SECONDS)">
            <div className="flex items-center justify-center gap-4">
              <button
                onClick={() => setSpeed(v => Math.max(1, v - 1))}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
              >
                -
              </button>
              <span className="text-2xl font-bold text-slate-800 dark:text-slate-200 w-16 text-center">
                {speed}s
              </span>
              <button
                onClick={() => setSpeed(v => Math.min(30, v + 1))}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
              >
                +
              </button>
            </div>
          </ConfigCard>

          {/* Steps */}
          <ConfigCard title="NUMBER OF STEPS">
            <div className="flex items-center justify-center gap-4">
              <button
                onClick={() => setTargetSteps(v => Math.max(1, v - 1))}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
              >
                -
              </button>
              <span className="text-2xl font-bold text-slate-800 dark:text-slate-200 w-16 text-center">
                {targetSteps}
              </span>
              <button
                onClick={() => setTargetSteps(v => Math.min(100, v + 1))}
                className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 flex items-center justify-center"
              >
                +
              </button>
            </div>
          </ConfigCard>

          {/* Font Size */}
          <ConfigCard title="FONT SIZE">
            <input
              type="range"
              min={2}
              max={12}
              value={fontSize}
              onChange={e => setFontSize(Number(e.target.value))}
              className="w-full"
            />
            <div className="text-center text-sm text-slate-500 dark:text-slate-400 mt-2">
              {fontSize}rem
            </div>
          </ConfigCard>

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

  // Playing / Countdown
  if (status === 'playing') {
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center p-4">
        <div className="text-slate-400 mb-4">
          Step {currentStep} / {targetSteps}
        </div>
        <div
          className="font-bold text-white transition-all"
          style={{ fontSize: `${fontSize}rem` }}
        >
          {display}
        </div>
        <button
          onClick={returnToConfig}
          className="mt-8 px-6 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-white"
        >
          Cancel
        </button>
      </div>
    )
  }

  // Pending - Number Pad
  if (status === 'pending') {
    const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '0']
    
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center p-4">
        <div className="text-2xl text-slate-400 mb-2">What's the result?</div>
        <div className="text-5xl font-bold text-white mb-8 min-h-16">
          {userAnswer || '_'}
        </div>
        
        <div className="grid grid-cols-3 gap-3 max-w-xs">
          {digits.map(d => (
            <button
              key={d}
              onClick={() => appendDigit(d)}
              className="w-16 h-16 rounded-xl bg-slate-700 hover:bg-slate-600 text-white text-2xl font-semibold transition-colors"
            >
              {d}
            </button>
          ))}
          <button
            onClick={clearInput}
            className="w-16 h-16 rounded-xl bg-red-600 hover:bg-red-500 text-white flex items-center justify-center transition-colors"
          >
            <Delete className="w-6 h-6" />
          </button>
        </div>
        
        <button
          onClick={checkAnswer}
          disabled={!userAnswer || userAnswer === '-'}
          className="mt-6 px-8 py-3 rounded-xl bg-green-600 hover:bg-green-500 disabled:bg-slate-600 disabled:cursor-not-allowed text-white font-semibold flex items-center gap-2 transition-colors"
        >
          <Check className="w-5 h-5" />
          Check
        </button>
      </div>
    )
  }

  // Result
  return (
    <div className={`min-h-screen flex flex-col items-center justify-center p-4 ${isCorrect ? 'bg-green-900' : 'bg-red-900'}`}>
      {isCorrect && (
        <Trophy className="w-20 h-20 text-yellow-400 mb-4" />
      )}
      <div className="text-4xl font-bold text-white mb-2">
        {isCorrect ? 'Correct!' : 'Wrong!'}
      </div>
      <div className="text-xl text-white/80 mb-2">
        Your answer: {userAnswer}
      </div>
      <div className="text-xl text-white/80 mb-8">
        Correct answer: {total}
      </div>
      
      {/* History */}
      <div className="flex flex-wrap justify-center gap-2 mb-8 max-w-md">
        {history.map((op, i) => (
          <span key={i} className="px-3 py-1 rounded-full bg-white/20 text-white text-sm">
            {op}
          </span>
        ))}
      </div>
      
      <div className="flex gap-4">
        <button
          onClick={startGame}
          className="px-6 py-3 rounded-xl bg-white/20 hover:bg-white/30 text-white font-semibold flex items-center gap-2 transition-colors"
        >
          <RotateCcw className="w-5 h-5" />
          Play Again
        </button>
        <button
          onClick={returnToConfig}
          className="px-6 py-3 rounded-xl bg-white/20 hover:bg-white/30 text-white font-semibold transition-colors"
        >
          Settings
        </button>
      </div>
    </div>
  )
}
