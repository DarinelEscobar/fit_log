import '../../domain/entities/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../pages/exercises_screen.dart';
import '../pages/edit_routine_screen.dart';


class RoutinesScreen extends ConsumerStatefulWidget {
  static const routeName = '/routines';
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  bool _isInactiveExpanded = false;

  @override
  Widget build(BuildContext context) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFCC97FF), Color(0xFF9C48EA)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(132, 44, 211, 0.25),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
               // Use standard add routine behaviour
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditRoutineScreen(plan: WorkoutPlan(id: 0, name: '', frequency: '', isActive: true))),
              );
            },
            child: const Icon(Icons.add, color: Color(0xFF47007C), size: 32),
          ),
        ),
      ),
      body: SafeArea(
        child: asyncPlans.when(
          data: (plans) {
            final activePlans = plans.where((plan) => plan.isActive).toList()
              ..sort((a, b) {
                final nameCompare = a.name.trim().toLowerCase().compareTo(
                  b.name.trim().toLowerCase(),
                );
                if (nameCompare != 0) return nameCompare;
                return a.id.compareTo(b.id);
              });
            final inactivePlans = plans.where((plan) => !plan.isActive).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'My Routines',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your weekly performance blueprint.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFADAAAB),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE ROUTINES',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFFADAAAB),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${activePlans.length} ACTIVE',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC97FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (activePlans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No hay rutinas activas',
                          style: TextStyle(color: Color(0xFFADAAAB)),
                        ),
                      ),
                    )
                  else
                    ...activePlans.map((plan) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExercisesScreen(planId: plan.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131314),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        plan.name,
                                                        style: const TextStyle(
                                                          fontFamily: 'Space Grotesk',
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.verified, color: Color(0xFFCC97FF), size: 16),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  plan.frequency,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFFADAAAB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.edit, size: 20, color: Color(0xFFADAAAB)),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => EditRoutineScreen(plan: plan),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 16),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.pause_circle, size: 20, color: Color(0xFFADAAAB)),
                                                onPressed: () {
                                                  ref.read(workoutPlanProvider.notifier).setPlanActive(plan.id, false);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    color: const Color(0xFFCC97FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFF262627), thickness: 1),
                  const SizedBox(height: 24),

                  InkWell(
                    onTap: () {
                      setState(() {
                        _isInactiveExpanded = !_isInactiveExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Color(0xFFADAAAB), size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'INACTIVE ROUTINES',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFFADAAAB),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isInactiveExpanded ? Icons.expand_less : Icons.expand_more,
                          color: const Color(0xFFADAAAB),
                        ),
                      ],
                    ),
                  ),

                  if (_isInactiveExpanded) ...[
                    const SizedBox(height: 24),
                    if (inactivePlans.isEmpty)
                      const Center(
                        child: Text(
                          'No hay rutinas inactivas',
                          style: TextStyle(color: Color(0xFFADAAAB)),
                        ),
                      )
                    else
                      ...inactivePlans.map((plan) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFADAAAB),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      plan.frequency,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Color(0xFF767576),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ref.read(workoutPlanProvider.notifier).setPlanActive(plan.id, true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.unarchive, size: 14, color: Color(0xFFCC97FF)),
                                      SizedBox(width: 8),
                                      Text(
                                        'ACTIVATE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFCC97FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
