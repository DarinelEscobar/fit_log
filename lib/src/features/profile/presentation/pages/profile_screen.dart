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
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _section(
                          context,
                          'Información',
                          [
                            _infoRow('Edad', '${user.age}'),
                            _infoRow('Género', user.gender),
                            _infoRow('Peso', '${user.weight} kg'),
                            _infoRow('Altura', '${user.height} cm'),
                            _infoRow('Nivel', user.experienceLevel),
                            _infoRow('Meta', user.goal),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _section(
                          context,
                          'Objetivos',
                          [
                            _infoRow('Peso', '${user.targetWeight} kg'),
                            _infoRow('BF', '${user.targetBodyFat}%'),
                            _infoRow('Cuello', '${user.targetNeck} cm'),
                            _infoRow('Hombros', '${user.targetShoulders} cm'),
                            _infoRow('Pecho', '${user.targetChest} cm'),
                            _infoRow('Abdomen', '${user.targetAbdomen} cm'),
                            _infoRow('Cintura', '${user.targetWaist} cm'),
                            _infoRow('Glúteos', '${user.targetGlutes} cm'),
                            _infoRow('Muslo', '${user.targetThigh} cm'),
                            _infoRow('Pantorrilla', '${user.targetCalf} cm'),
                            _infoRow('Brazo', '${user.targetArm} cm'),
                            _infoRow('Antebrazo', '${user.targetForearm} cm'),
                          ],
                        ),
                        if (last != null) ...[
                          const SizedBox(height: 12),
                          _section(
                            context,
                            'Últimas métricas (${last.date.toIso8601String().split('T').first})',
                            [
                              _infoRow('Peso', '${last.weight} kg'),
                              _infoRow('BF', '${last.bodyFat}%'),
                              _infoRow('Cuello', '${last.neck} cm'),
                              _infoRow('Hombros', '${last.shoulders} cm'),
                              _infoRow('Pecho', '${last.chest} cm'),
                              _infoRow('Abdomen', '${last.abdomen} cm'),
                              _infoRow('Cintura', '${last.waist} cm'),
                              _infoRow('Glúteos', '${last.glutes} cm'),
                              _infoRow('Muslo', '${last.thigh} cm'),
                              _infoRow('Pantorrilla', '${last.calf} cm'),
                              _infoRow('Brazo', '${last.arm} cm'),
                              _infoRow('Antebrazo', '${last.forearm} cm'),
                            ],
                          ),
                        ],
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
            );
          },
        );
      },
    );
  }
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _section(BuildContext context, String title, List<Widget> children) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}
