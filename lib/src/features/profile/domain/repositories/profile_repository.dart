import '../entities/user_profile.dart';
import '../entities/body_metric.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getUserProfile();
  Future<List<BodyMetric>> getBodyMetrics();
  Future<void> updateUserProfile(UserProfile profile);
  Future<void> addBodyMetric(BodyMetric metric);
}
