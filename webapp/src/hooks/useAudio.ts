import { useRef, useCallback } from 'react'

const BEEP_URL = 'https://www.soundjay.com/buttons/beep-01a.mp3'

export function useAudio() {
  const audioRef = useRef<HTMLAudioElement | null>(null)

  const playBeep = useCallback(async (volume: number = 0.3) => {
    try {
      if (!audioRef.current) {
        audioRef.current = new Audio(BEEP_URL)
      }
      audioRef.current.volume = Math.min(1, Math.max(0, volume))
      audioRef.current.currentTime = 0
      await audioRef.current.play()
    } catch (error) {
      console.warn('Failed to play audio:', error)
    }
  }, [])

  const stop = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
      audioRef.current.currentTime = 0
    }
  }, [])

  return { playBeep, stop }
}
