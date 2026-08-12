abstract class Loader<T> {
  Future<T> load(String path);
}
