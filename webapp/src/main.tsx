import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import './index.css'

// Screens
import Home from './screens/Home'
import Farben from './screens/Farben'
import Kettenrechner from './screens/Kettenrechner'
import Timers from './screens/Timers'
import Intervall from './screens/Intervall'
import SoundCounter from './screens/SoundCounter'
import MotionCounter from './screens/MotionCounter'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/farben" element={<Farben />} />
        <Route path="/kettenrechner" element={<Kettenrechner />} />
        <Route path="/timers" element={<Timers />} />
        <Route path="/intervall" element={<Intervall />} />
        <Route path="/sound-counter" element={<SoundCounter />} />
        <Route path="/motion-counter" element={<MotionCounter />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
)
