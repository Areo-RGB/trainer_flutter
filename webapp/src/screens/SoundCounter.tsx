import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Mic, MicOff, RotateCcw, Maximize2 } from 'lucide-react'
import { Card, ConfigCard } from '../components/Card'

export default function SoundCounter() {
  const navigate = useNavigate()
  
  const [isListening, setIsListening] = useState(false)
  const [hasPermission, setHasPermission] = useState(false)
  const [counter, setCounter] = useState(0)
  const [currentAmplitude, setCurrentAmplitude] = useState(-160)
  const [threshold, setThreshold] = useState(-30)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [showConfigView, setShowConfigView] = useState(true)
  const [startTime, setStartTime] = useState<Date | null>(null)
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = useState<string>('')
  
  const audioContextRef = useRef<AudioContext | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const animationRef = useRef<number | null>(null)
  const wasAboveThresholdRef = useRef(false)

  const loadDevices = useCallback(async () => {
    try {
      // Request permission first
      await navigator.mediaDevices.getUserMedia({ audio: true })
      setHasPermission(true)
      
      const allDevices = await navigator.mediaDevices.enumerateDevices()
      const audioInputs = allDevices.filter(d => d.kind === 'audioinput')
      setDevices(audioInputs)
      if (audioInputs.length > 0 && !selectedDeviceId) {
        setSelectedDeviceId(audioInputs[0].deviceId)
      }
    } catch (e) {
      setErrorMessage('Microphone permission denied')
      setHasPermission(false)
    }
  }, [selectedDeviceId])

  const startListening = useCallback(async () => {
    setErrorMessage(null)
    
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: selectedDeviceId ? { deviceId: { exact: selectedDeviceId } } : true
      })
      streamRef.current = stream
      setHasPermission(true)
      
      const audioContext = new AudioContext()
      audioContextRef.current = audioContext
      
      const source = audioContext.createMediaStreamSource(stream)
      const analyser = audioContext.createAnalyser()
      analyser.fftSize = 1024
      analyser.smoothingTimeConstant = 0.3
      source.connect(analyser)
      analyserRef.current = analyser
      
      setIsListening(true)
      setCounter(0)
      setStartTime(new Date())
      wasAboveThresholdRef.current = false
      
      // Start amplitude monitoring
      const dataArray = new Uint8Array(analyser.frequencyBinCount)
      
      const tick = () => {
        if (!analyserRef.current) return
        
        analyserRef.current.getByteFrequencyData(dataArray)
        
        // Calculate RMS amplitude
        let sum = 0
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i] * dataArray[i]
        }
        const rms = Math.sqrt(sum / dataArray.length)
        
        // Convert to dBFS-like scale (0-255 -> -160 to 0)
        const dbfs = rms > 0 ? 20 * Math.log10(rms / 255) : -160
        setCurrentAmplitude(dbfs)
        
        // Check threshold crossing
        const isAboveThreshold = dbfs >= threshold
        
        if (isAboveThreshold && !wasAboveThresholdRef.current) {
          setCounter(c => c + 1)
          wasAboveThresholdRef.current = true
        } else if (!isAboveThreshold && wasAboveThresholdRef.current) {
          wasAboveThresholdRef.current = false
        }
        
        animationRef.current = requestAnimationFrame(tick)
      }
      
      tick()
    } catch (e) {
      setErrorMessage(`Failed to start: ${e}`)
    }
  }, [selectedDeviceId, threshold])

  const stopListening = useCallback(() => {
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current)
    }
    if (audioContextRef.current) {
      audioContextRef.current.close()
      audioContextRef.current = null
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(t => t.stop())
      streamRef.current = null
    }
    analyserRef.current = null
    setIsListening(false)
  }, [])

  useEffect(() => {
    return () => {
      stopListening()
    }
  }, [stopListening])

  const resetCounter = () => {
    setCounter(0)
    setStartTime(new Date())
  }

  const normalizedAmplitude = Math.max(0, Math.min(1, (currentAmplitude + 80) / 80))
  const elapsed = startTime ? (Date.now() - startTime.getTime()) / 1000 : 0
  const rate = elapsed > 0 ? counter / elapsed : 0

  // Full-screen counter view
  if (!showConfigView) {
    return (
      <div 
        className="min-h-screen bg-slate-900 flex flex-col items-center justify-center p-4"
        onClick={resetCounter}
        onDoubleClick={() => setShowConfigView(true)}
      >
        <div 
          className={`w-72 h-72 rounded-full flex flex-col items-center justify-center transition-all ${
            isListening ? 'bg-[#5076a3]/20' : 'bg-slate-800'
          }`}
          style={{
            borderWidth: 12,
            borderStyle: 'solid',
            borderColor: isListening 
              ? `rgba(80, 118, 163, ${normalizedAmplitude})` 
              : 'transparent',
            boxShadow: isListening && wasAboveThresholdRef.current 
              ? '0 0 30px rgba(80, 118, 163, 0.5)' 
              : 'none'
          }}
        >
          <span className="text-8xl font-bold text-[#5076a3]">{counter}</span>
        </div>
        <span className="text-2xl text-slate-400 mt-4">sounds</span>
        {isListening && (
          <span className="text-lg text-slate-500 mt-2">{rate.toFixed(2)} / sec</span>
        )}
        <div className="flex gap-4 mt-8">
          <button
            onClick={(e) => { e.stopPropagation(); isListening ? stopListening() : startListening() }}
            className={`px-8 py-4 rounded-xl font-semibold flex items-center gap-2 ${
              isListening ? 'bg-red-500 text-white' : 'bg-[#5076a3] text-white'
            }`}
          >
            {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
            {isListening ? 'Stop' : 'Start'}
          </button>
        </div>
        <p className="text-sm text-slate-500 mt-4">Tap to reset • Double-tap for settings</p>
      </div>
    )
  }

  // Config view
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      <header className="sticky top-0 z-10 bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center gap-3">
          <button
            onClick={() => { stopListening(); navigate('/') }}
            className="p-2 -ml-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </button>
          <h1 className="text-lg font-semibold text-slate-800 dark:text-slate-200 flex-1">
            Sound Counter
          </h1>
          <button
            onClick={() => setShowConfigView(false)}
            className="p-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
          >
            <Maximize2 className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </button>
        </div>
      </header>

      <main className="max-w-md mx-auto p-6 space-y-4">
        {errorMessage && (
          <div className="p-4 rounded-xl bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 flex items-center gap-3">
            <MicOff className="w-5 h-5" />
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Counter Display */}
        <div className="flex justify-center">
          <div 
            className={`w-48 h-48 rounded-full flex flex-col items-center justify-center ${
              isListening ? 'bg-[#5076a3]/20' : 'bg-slate-200 dark:bg-slate-800'
            }`}
            style={{
              borderWidth: 8,
              borderStyle: 'solid',
              borderColor: isListening 
                ? `rgba(80, 118, 163, ${normalizedAmplitude})` 
                : 'transparent',
            }}
          >
            <span className="text-5xl font-bold text-[#5076a3]">{counter}</span>
            <span className="text-slate-500 dark:text-slate-400">sounds</span>
          </div>
        </div>

        {/* Amplitude Indicator */}
        {isListening && (
          <div className="space-y-2">
            <div className="text-center text-sm text-slate-500 dark:text-slate-400">
              Amplitude: {currentAmplitude.toFixed(1)} dBFS
            </div>
            <div className="h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
              <div 
                className={`h-full transition-all ${
                  currentAmplitude >= threshold ? 'bg-green-500' : 'bg-[#5076a3]'
                }`}
                style={{ width: `${normalizedAmplitude * 100}%` }}
              />
            </div>
          </div>
        )}

        {/* Microphone Selection */}
        <Card className="p-4">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">
              Microphone
            </span>
            <button
              onClick={loadDevices}
              disabled={isListening}
              className="text-[#5076a3] text-sm hover:underline disabled:opacity-50"
            >
              Refresh
            </button>
          </div>
          {devices.length === 0 ? (
            <button
              onClick={loadDevices}
              disabled={isListening}
              className="w-full py-2 rounded-lg border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <Mic className="w-4 h-4" />
              Load Microphones
            </button>
          ) : (
            <select
              value={selectedDeviceId}
              onChange={e => setSelectedDeviceId(e.target.value)}
              disabled={isListening}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 disabled:opacity-50"
            >
              {devices.map(d => (
                <option key={d.deviceId} value={d.deviceId}>
                  {d.label || `Microphone ${d.deviceId.slice(0, 8)}`}
                </option>
              ))}
            </select>
          )}
        </Card>

        {/* Threshold Control */}
        <ConfigCard title="THRESHOLD">
          <div className="text-center text-xl font-bold text-slate-800 dark:text-slate-200 mb-2">
            {threshold} dBFS
          </div>
          <input
            type="range"
            min={-80}
            max={0}
            value={threshold}
            onChange={e => setThreshold(Number(e.target.value))}
            disabled={isListening}
            className="w-full disabled:opacity-50"
          />
          <div className="text-center text-sm text-slate-500 dark:text-slate-400 mt-2">
            Lower = more sensitive
          </div>
        </ConfigCard>

        {/* Controls */}
        <div className="flex gap-3 justify-center">
          <button
            onClick={isListening ? stopListening : startListening}
            className={`px-6 py-3 rounded-xl font-semibold flex items-center gap-2 ${
              isListening 
                ? 'bg-red-500 hover:bg-red-600 text-white' 
                : 'bg-[#5076a3] hover:bg-[#3a5a7c] text-white'
            }`}
          >
            {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
            {isListening ? 'Stop' : 'Start Listening'}
          </button>
          <button
            onClick={resetCounter}
            className="p-3 rounded-xl border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <RotateCcw className="w-5 h-5" />
          </button>
        </div>

        {!hasPermission && !errorMessage && (
          <div className="p-4 rounded-xl bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 text-sm">
            Click "Load Microphones" or "Start Listening" to grant access
          </div>
        )}
      </main>
    </div>
  )
}
