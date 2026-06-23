import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/app_data/presentation/pages/data_screen.dart';
import '../features/home/presentation/pages/home_dashboard_screen.dart';
import '../features/performance/presentation/pages/performance_dashboard_screen.dart';
import '../features/routines/domain/entities/active_workout_session_draft.dart';
import '../features/routines/domain/usecases/active_session_draft_usecases.dart';
import '../features/routines/presentation/pages/start_routine_screen.dart';
import '../features/routines/presentation/providers/workout_plan_repository_provider.dart';
import '../features/routines/presentation/pages/routines_screen.dart';
import '../theme/kinetic_noir.dart';
import 'widgets/kinetic_bottom_nav_bar.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  bool _checkedRecoverableSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecoverableSession();
    });
  }

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

  Future<void> _checkRecoverableSession() async {
    if (_checkedRecoverableSession) {
      return;
    }
    _checkedRecoverableSession = true;

    final repo = ref.read(workoutPlanRepositoryProvider);
    final draft = await GetActiveSessionDraftUseCase(repo)();
    if (!mounted || draft == null) {
      return;
    }

    final shouldResume = await _showRecoveryPrompt(draft);
    if (!mounted || shouldResume == null) {
      return;
    }

    if (!shouldResume) {
      await ClearActiveSessionDraftUseCase(repo)();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartRoutineScreen(
          plan: draft.plan,
          recoveredDraft: draft,
        ),
      ),
    );
  }

  Future<bool?> _showRecoveryPrompt(ActiveWorkoutSessionDraft draft) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: KineticNoirPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Resume session?',
          style: KineticNoirTypography.headline(size: 22),
        ),
        content: Text(
          '${draft.plan.name} has an unfinished session.',
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'DISCARD',
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.error,
                letterSpacing: 1,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
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
