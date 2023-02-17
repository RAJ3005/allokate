extension ListModifier<T> on List<T> {
  /// Returns a new [List] ordered with the given comparator.
  List<T> order([int Function(T a, T b) comparator]) {
    List<T> list = List.from(this);
    list.sort(comparator);
    return list;
  }
}
