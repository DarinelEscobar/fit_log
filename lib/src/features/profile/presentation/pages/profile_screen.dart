import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import 'metrics_chart_screen.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/add_body_metric_dialog.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../domain/usecases/add_body_metric_usecase.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/body_metric.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final metricsAsync = ref.watch(bodyMetricsProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        return metricsAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (metrics) {
            final last = metrics.isNotEmpty ? metrics.last : null;
            return Scaffold(
              appBar: AppBar(title: const Text('Perfil')),
              floatingActionButton: user == null
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'edit',
                          onPressed: () async {
                            final updated = await showDialog<UserProfile>(
                              context: context,
                              builder: (_) => EditProfileDialog(user: user),
                            );
                            if (updated != null) {
                              final repo = ProfileRepositoryImpl();
                              await UpdateUserProfileUseCase(repo)(updated);
                              ref.invalidate(userProfileProvider);
                            }
                          },
                          child: const Icon(Icons.edit),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'metric',
                          onPressed: () async {
                            final metric = await showDialog<BodyMetric>(
                              context: context,
                              builder: (_) => AddBodyMetricDialog(
                                user: user,
                                last: last,
                              ),
                            );
                            if (metric != null) {
                              final repo = ProfileRepositoryImpl();
                              await AddBodyMetricUseCase(repo)(metric);
                              ref.invalidate(bodyMetricsProvider);
                            }
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
              body: user == null
                  ? const Center(child: Text('No user data'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edad: ${user.age}'),
                          Text('Género: ${user.gender}'),
                          Text('Peso: ${user.weight} kg'),
                          Text('Altura: ${user.height} cm'),
                          Text('Nivel: ${user.experienceLevel}'),
                          Text('Meta: ${user.goal}'),
                          const Divider(),
                          Text('Peso deseado: ${user.targetWeight} kg'),
                          Text('BF deseado: ${user.targetBodyFat}%'),
                          Text('Cuello deseado: ${user.targetNeck} cm'),
                          Text('Hombros deseados: ${user.targetShoulders} cm'),
                          Text('Pecho deseado: ${user.targetChest} cm'),
                          Text('Abdomen deseado: ${user.targetAbdomen} cm'),
                          Text('Cintura deseada: ${user.targetWaist} cm'),
                          Text('Glúteos deseados: ${user.targetGlutes} cm'),
                          Text('Muslo deseado: ${user.targetThigh} cm'),
                          Text('Pantorrilla deseada: ${user.targetCalf} cm'),
                          Text('Brazo deseado: ${user.targetArm} cm'),
                          Text('Antebrazo deseado: ${user.targetForearm} cm'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MetricsChartScreen(),
                                ),
                              );
                            },
                            child: const Text('Ver gráfica'),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
