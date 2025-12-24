import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Play, Square, RotateCcw, Maximize2 } from 'lucide-react'
import { Card } from '../components/Card'

const TRIPWIRE_ZONE_WIDTH = 0.1 // 10% of frame width

export default function MotionCounter() {
  const navigate = useNavigate()
  
  const [isDetecting, setIsDetecting] = useState(false)
  const [counter, setCounter] = useState(0)
  const [tripwirePosition, setTripwirePosition] = useState(0.5)
  const [sensitivity, setSensitivity] = useState(30)
  const [showConfigView, setShowConfigView] = useState(true)
  const [startTime, setStartTime] = useState<Date | null>(null)
  const [currentMotionLevel, setCurrentMotionLevel] = useState(0)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [selectedDeviceId, setSelectedDeviceId] = useState<string>('')
  const [isInitialized, setIsInitialized] = useState(false)
  
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const animationRef = useRef<number | null>(null)
  const previousFrameRef = useRef<Uint8ClampedArray | null>(null)
  const motionDetectedRef = useRef(false)

  const loadDevices = useCallback(async () => {
    try {
      await navigator.mediaDevices.getUserMedia({ video: true })
      const allDevices = await navigator.mediaDevices.enumerateDevices()
      const videoInputs = allDevices.filter(d => d.kind === 'videoinput')
      setDevices(videoInputs)
      if (videoInputs.length > 0 && !selectedDeviceId) {
        setSelectedDeviceId(videoInputs[0].deviceId)
      }
    } catch (e) {
      setErrorMessage('Camera permission denied')
    }
  }, [selectedDeviceId])

  const initCamera = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: selectedDeviceId 
          ? { deviceId: { exact: selectedDeviceId }, width: 640, height: 480 }
          : { width: 640, height: 480 }
      })
      streamRef.current = stream
      
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        await videoRef.current.play()
        setIsInitialized(true)
        setErrorMessage(null)
      }
    } catch (e) {
      setErrorMessage(`Failed to init camera: ${e}`)
    }
  }, [selectedDeviceId])

  useEffect(() => {
    loadDevices()
  }, [loadDevices])

  useEffect(() => {
    if (selectedDeviceId) {
      initCamera()
    }
    return () => {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(t => t.stop())
      }
    }
  }, [selectedDeviceId, initCamera])

  const startDetection = () => {
    if (!videoRef.current || !canvasRef.current) return
    
    setIsDetecting(true)
    setCounter(0)
    setStartTime(new Date())
    previousFrameRef.current = null
    motionDetectedRef.current = false
    
    const video = videoRef.current
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d', { willReadFrequently: true })
    if (!ctx) return
    
    canvas.width = video.videoWidth || 640
    canvas.height = video.videoHeight || 480
    
    const processFrame = () => {
      if (!ctx || !video.videoWidth) {
        animationRef.current = requestAnimationFrame(processFrame)
        return
      }
      
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      const currentFrame = imageData.data
      
      // Convert to grayscale
      const grayscale = new Uint8ClampedArray(canvas.width * canvas.height)
      for (let i = 0, j = 0; i < currentFrame.length; i += 4, j++) {
        grayscale[j] = Math.round((currentFrame[i] + currentFrame[i + 1] + currentFrame[i + 2]) / 3)
      }
      
      if (previousFrameRef.current) {
        const width = canvas.width
        const height = canvas.height
        
        // Calculate tripwire zone
        const zoneStart = Math.floor((tripwirePosition - TRIPWIRE_ZONE_WIDTH / 2) * width)
        const zoneEnd = Math.floor((tripwirePosition + TRIPWIRE_ZONE_WIDTH / 2) * width)
        
        let motionPixels = 0
        let totalPixels = 0
        
        for (let y = 0; y < height; y++) {
          for (let x = zoneStart; x < zoneEnd; x++) {
            const idx = y * width + x
            const diff = Math.abs(grayscale[idx] - previousFrameRef.current[idx])
            if (diff > sensitivity) {
              motionPixels++
            }
            totalPixels++
          }
        }
        
        const motionLevel = totalPixels > 0 ? motionPixels / totalPixels : 0
        setCurrentMotionLevel(motionLevel)
        
        const hasMotion = motionLevel > 0.05
        
        if (hasMotion && !motionDetectedRef.current) {
          motionDetectedRef.current = true
        } else if (!hasMotion && motionDetectedRef.current) {
          motionDetectedRef.current = false
          setCounter(c => c + 1)
        }
      }
      
      previousFrameRef.current = grayscale
      animationRef.current = requestAnimationFrame(processFrame)
    }
    
    processFrame()
  }

  const stopDetection = () => {
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current)
    }
    setIsDetecting(false)
    setCurrentMotionLevel(0)
  }

  const resetCounter = () => {
    setCounter(0)
    setStartTime(new Date())
  }

  const elapsed = startTime ? (Date.now() - startTime.getTime()) / 1000 : 0
  const rate = elapsed > 0 ? counter / elapsed : 0

  // Camera Preview with Tripwire overlay
  const CameraPreview = ({ showTripwire = true, height }: { showTripwire?: boolean; height?: string }) => (
    <div className={`relative bg-black rounded-xl overflow-hidden ${height || 'aspect-video'}`}>
      <video
        ref={videoRef}
        autoPlay
        playsInline
        muted
        className="w-full h-full object-contain"
      />
      <canvas ref={canvasRef} className="hidden" />
      
      {/* Tripwire overlay */}
      {showTripwire && (
        <div 
          className="absolute top-0 bottom-0 pointer-events-none"
          style={{
            left: `${(tripwirePosition - TRIPWIRE_ZONE_WIDTH / 2) * 100}%`,
            width: `${TRIPWIRE_ZONE_WIDTH * 100}%`,
            backgroundColor: isDetecting 
              ? `rgba(80, 118, 163, ${0.2 + currentMotionLevel * 0.8})`
              : 'rgba(80, 118, 163, 0.2)',
            borderLeft: '2px solid #5076a3',
            borderRight: '2px solid #5076a3',
          }}
        />
      )}
      
      {!isInitialized && (
        <div className="absolute inset-0 flex items-center justify-center text-white">
          Loading camera...
        </div>
      )}
    </div>
  )

  // Fullscreen counter view
  if (!showConfigView) {
    return (
      <div 
        className="min-h-screen bg-slate-900 flex flex-col"
        onClick={resetCounter}
        onDoubleClick={() => setShowConfigView(true)}
      >
        <div className="flex-1 p-4">
          <CameraPreview showTripwire={true} height="h-full" />
        </div>
        <div className="p-6 text-center">
          <div className="text-6xl font-bold text-[#5076a3] mb-2">{counter}</div>
          <div className="text-xl text-slate-400 mb-2">crossings</div>
          {isDetecting && (
            <div className="text-slate-500">{rate.toFixed(2)} / sec</div>
          )}
          <div className="flex justify-center gap-4 mt-6">
            <button
              onClick={(e) => { e.stopPropagation(); isDetecting ? stopDetection() : startDetection() }}
              className={`px-6 py-3 rounded-xl font-semibold flex items-center gap-2 ${
                isDetecting ? 'bg-red-500 text-white' : 'bg-[#5076a3] text-white'
              }`}
            >
              {isDetecting ? <Square className="w-5 h-5" /> : <Play className="w-5 h-5" />}
              {isDetecting ? 'Stop' : 'Start'}
            </button>
          </div>
        </div>
      </div>
    )
  }

  // Config view
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      <header className="sticky top-0 z-10 bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-4xl mx-auto px-4 h-14 flex items-center gap-3">
          <button
            onClick={() => { stopDetection(); navigate('/') }}
            className="p-2 -ml-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </button>
          <h1 className="text-lg font-semibold text-slate-800 dark:text-slate-200 flex-1">
            Motion Counter
          </h1>
          <button
            onClick={() => setShowConfigView(false)}
            className="p-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors"
          >
            <Maximize2 className="w-5 h-5 text-slate-600 dark:text-slate-400" />
          </button>
        </div>
      </header>

      <main className="max-w-2xl mx-auto p-4 space-y-4">
        {errorMessage && (
          <div className="p-4 rounded-xl bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400">
            {errorMessage}
          </div>
        )}

        {/* Camera Preview */}
        <CameraPreview showTripwire={true} />

        {/* Counter + Controls */}
        <Card className="p-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <span className="text-3xl font-bold text-[#5076a3]">{counter}</span>
              <span className="text-slate-500 dark:text-slate-400 ml-2">crossings</span>
            </div>
            {isDetecting && (
              <span className="text-slate-500 dark:text-slate-400">{rate.toFixed(2)} / sec</span>
            )}
          </div>
          
          {/* Tripwire Position */}
          <div className="mb-4">
            <div className="flex justify-between mb-1">
              <span className="text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">
                Tripwire: {Math.round(tripwirePosition * 100)}%
              </span>
            </div>
            <input
              type="range"
              min={0.1}
              max={0.9}
              step={0.01}
              value={tripwirePosition}
              onChange={e => setTripwirePosition(Number(e.target.value))}
              disabled={isDetecting}
              className="w-full disabled:opacity-50"
            />
          </div>
          
          {/* Sensitivity */}
          <div className="mb-4">
            <div className="flex justify-between mb-1">
              <span className="text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">
                Sensitivity: {sensitivity}
              </span>
            </div>
            <input
              type="range"
              min={5}
              max={100}
              value={sensitivity}
              onChange={e => setSensitivity(Number(e.target.value))}
              disabled={isDetecting}
              className="w-full disabled:opacity-50"
            />
          </div>
          
          {/* Camera Selection */}
          {devices.length > 1 && (
            <div className="mb-4">
              <label className="block text-xs font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase mb-1">
                Camera
              </label>
              <select
                value={selectedDeviceId}
                onChange={e => setSelectedDeviceId(e.target.value)}
                disabled={isDetecting}
                className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 disabled:opacity-50"
              >
                {devices.map(d => (
                  <option key={d.deviceId} value={d.deviceId}>
                    {d.label || `Camera ${d.deviceId.slice(0, 8)}`}
                  </option>
                ))}
              </select>
            </div>
          )}
          
          {/* Buttons */}
          <div className="flex gap-3 justify-center">
            <button
              onClick={isDetecting ? stopDetection : startDetection}
              disabled={!isInitialized}
              className={`px-6 py-3 rounded-xl font-semibold flex items-center gap-2 disabled:opacity-50 ${
                isDetecting 
                  ? 'bg-red-500 hover:bg-red-600 text-white' 
                  : 'bg-[#5076a3] hover:bg-[#3a5a7c] text-white'
              }`}
            >
              {isDetecting ? <Square className="w-5 h-5" /> : <Play className="w-5 h-5" />}
              {isDetecting ? 'Stop' : 'Start'}
            </button>
            <button
              onClick={resetCounter}
              className="p-3 rounded-xl border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              <RotateCcw className="w-5 h-5" />
            </button>
          </div>
        </Card>
      </main>
    </div>
  )
}
