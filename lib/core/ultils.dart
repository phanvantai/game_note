import 'dart:math';

T randomObject<T>(List<T> list) {
  final random = Random();
  return list[random.nextInt(list.length)];
}

List<T> rotateList<T>(List<T> list) {
  if (list.length < 2) {
    return list;
  }
  list.insert(1, list.last);
  list.removeLast();
  return list;
}

List<Map<T, T>> createMaps<T>(List<T> list) {
  List<Map<T, T>> maps = [];
  for (int i = 0; i < list.length; i++) {
    if (i % 2 == 1) {
      maps.add({list[i - 1]: list[i]});
    }
  }
  return maps;
}
