/// Obtiene el nombre público del autor sin acoplar el repositorio a su perfil.
abstract interface class PostAuthorNameResolver {
  Future<String> resolve(String authorId);
}
