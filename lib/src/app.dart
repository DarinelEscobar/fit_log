import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/routines/presentation/pages/routines_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/routines',          // ← abre la vista principal al iniciar
  routes: [
    GoRoute(
      path: '/routines',
      name: RoutinesScreen.routeName,
      builder: (_, __) => const RoutinesScreen(),
    ),

  ],
);
