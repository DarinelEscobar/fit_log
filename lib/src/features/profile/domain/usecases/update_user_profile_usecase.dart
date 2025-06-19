import '../repositories/profile_repository.dart';
import '../entities/user_profile.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository _repo;
  const UpdateUserProfileUseCase(this._repo);

  Future<void> call(UserProfile profile) =>
      _repo.updateUserProfile(profile);
}
