import 'package:flutter/material.dart';
import '../features/routines/presentation/pages/routines_screen.dart';
import '../features/history/presentation/pages/logs_screen.dart';
import '../features/app_data/presentation/pages/data_screen.dart';
import '../features/profile/presentation/pages/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _HomeTab(onNavigateToRoutines: () => setState(() => _currentIndex = 1)),
      const RoutinesScreen(),
      const LogsScreen(),
      const _StatsTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFCC97FF)),
          onPressed: () {},
        ),
        title: const Text(
          'FIT LOG',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFCC97FF),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFADAAAB)),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A191B).withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(132, 44, 211, 0.06),
                blurRadius: 32,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            indicatorColor: Colors.transparent,
            destinations: [
              NavigationDestination(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      color: _currentIndex == 0 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HOME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _currentIndex == 0 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                      ),
                    ),
                  ],
                ),
                label: '',
              ),
              NavigationDestination(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 1 ? Icons.fitness_center : Icons.fitness_center_outlined,
                      color: _currentIndex == 1 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ROUTINES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _currentIndex == 1 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                      ),
                    ),
                  ],
                ),
                label: '',
              ),
              NavigationDestination(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 2 ? Icons.history : Icons.history_outlined,
                      color: _currentIndex == 2 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HISTORY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _currentIndex == 2 ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
                      ),
                    ),
                  ],
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onNavigateToRoutines;

  const _HomeTab({required this.onNavigateToRoutines});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: -1,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'WELCOME TO\n'),
                TextSpan(
                  text: 'FIT LOG',
                  style: TextStyle(
                    color: Color(0xFFCC97FF),
                    shadows: [
                      Shadow(
                        color: Color.fromRGBO(204, 151, 255, 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Track your workouts, monitor your progress, and stay consistent.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFADAAAB),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),

          GestureDetector(
            onTap: onNavigateToRoutines,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131314),
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFFCC97FF), width: 2),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'START TRACKING',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a routine from your library to begin logging your session.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFADAAAB),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC97FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VIEW WORKOUT ROUTINES',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Color(0xFF47007C),
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward, color: Color(0xFF47007C), size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.fitness_center, size: 160, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'DATA MANAGEMENT',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFADAAAB),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFF484849).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A191B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.backup, color: Color(0xFFCC97FF), size: 28),
                      SizedBox(height: 16),
                      Text(
                        'DATA & BACKUPS',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your local data. Export your workout history to JSON for safekeeping, or import a previous backup.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFADAAAB),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'MANAGE DATA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Color(0xFFCC97FF),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Color(0xFFCC97FF), size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Próximamente: Estadísticas', style: TextStyle(color: Colors.white)));
}
