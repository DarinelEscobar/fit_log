import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/get_body_metrics_usecase.dart';

final _repoProvider = Provider((_) => ProfileRepositoryImpl());

final userProfileProvider = FutureProvider((ref) {
  final usecase = GetUserProfileUseCase(ref.watch(_repoProvider));
  return usecase();
});

final bodyMetricsProvider = FutureProvider((ref) {
  final usecase = GetBodyMetricsUseCase(ref.watch(_repoProvider));
  return usecase();
});
