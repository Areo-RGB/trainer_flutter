import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/kettenrechner_screen.dart';
import 'screens/timers_screen.dart';
import 'screens/farben_screen.dart';
import 'screens/intervall_screen.dart';
import 'screens/sound_counter_screen.dart';
import 'screens/motion_counter_screen.dart';

/// Application router configuration.
final GoRouter router = GoRouter(
  initialLocation: '/motion-counter',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/kettenrechner',
      builder: (context, state) => const KettenrechnerScreen(),
    ),
    GoRoute(
      path: '/timers',
      builder: (context, state) => const TimersScreen(),
    ),
    GoRoute(
      path: '/farben',
      builder: (context, state) => const FarbenScreen(),
    ),
    GoRoute(
      path: '/intervall',
      builder: (context, state) => const IntervallScreen(),
    ),
    GoRoute(
      path: '/sound-counter',
      builder: (context, state) => const SoundCounterScreen(),
    ),
    GoRoute(
      path: '/motion-counter',
      builder: (context, state) => const MotionCounterScreen(),
    ),
  ],
);
