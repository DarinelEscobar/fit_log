import 'package:flutter/material.dart';
import '../features/app_data/presentation/pages/data_screen.dart';
import '../features/home/presentation/pages/home_dashboard_screen.dart';
import '../features/performance/presentation/pages/performance_dashboard_screen.dart';
import '../features/routines/presentation/pages/routines_screen.dart';
import '../theme/kinetic_noir.dart';
import 'widgets/kinetic_bottom_nav_bar.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Future<void> _openDataManagement() async {
    final result = await Navigator.push<DataScreenResult>(
      context,
      MaterialPageRoute(builder: (_) => const DataScreen()),
    );
    if (!mounted) return;
    if (result == DataScreenResult.goRoutines) {
      _selectTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboardScreen(
            onOpenDataManagement: _openDataManagement,
            onOpenRoutines: () => _selectTab(1),
          ),
          if (_loadedTabs.contains(1))
            const RoutinesScreen()
          else
            const SizedBox.shrink(),
          if (_loadedTabs.contains(2))
            const PerformanceDashboardScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: KineticBottomNavBar(
        selectedIndex: _currentIndex,
        onTap: _selectTab,
        items: const [
          KineticBottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          KineticBottomNavItem(
              icon: Icons.fitness_center_rounded, label: 'Routines'),
          KineticBottomNavItem(
            icon: Icons.show_chart_rounded,
            label: 'Performance',
          ),
        ],
      ),
    );
  }
}
