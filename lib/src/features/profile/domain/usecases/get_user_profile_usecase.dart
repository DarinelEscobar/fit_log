import '../repositories/profile_repository.dart';
import '../entities/user_profile.dart';

class GetUserProfileUseCase {
  final ProfileRepository _repo;
  const GetUserProfileUseCase(this._repo);

  Future<UserProfile?> call() => _repo.getUserProfile();
}
