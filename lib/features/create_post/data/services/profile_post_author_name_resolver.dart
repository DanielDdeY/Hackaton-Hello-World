import '../../../../home/user_profile.dart';
import '../../domain/services/post_author_name_resolver.dart';

final class ProfilePostAuthorNameResolver implements PostAuthorNameResolver {
  const ProfilePostAuthorNameResolver(this._profiles);

  final UserProfileStore _profiles;

  @override
  Future<String> resolve(String authorId) async {
    final profile = await _profiles.load(
      authorId,
      fallbackName: 'Vecino',
      fallbackBio: '',
      fallbackDepartment: '',
      fallbackProvince: '',
      fallbackDistrict: '',
    );
    final name = profile?.name.trim();
    return name == null || name.isEmpty ? 'Vecino' : name;
  }
}
