import '../repositories/profile_repository.dart';
import '../entities/body_metric.dart';

class AddBodyMetricUseCase {
  final ProfileRepository _repo;
  const AddBodyMetricUseCase(this._repo);

  Future<void> call(BodyMetric metric) => _repo.addBodyMetric(metric);
}
