import '../repositories/profile_repository.dart';
import '../entities/body_metric.dart';

class GetBodyMetricsUseCase {
  final ProfileRepository _repo;
  const GetBodyMetricsUseCase(this._repo);

  Future<List<BodyMetric>> call() => _repo.getBodyMetrics();
}
