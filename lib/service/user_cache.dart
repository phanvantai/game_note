import '../firebase/firestore/user/gn_user.dart';

class UserCache {
  final Map<String, GNUser> _cache = {};

  // Check if user exists in the cache
  GNUser? getUser(String userId) {
    return _cache[userId];
  }

  // Add user to the cache
  void addUser(GNUser user) {
    _cache[user.id] = user;
  }

  // Check if the user is already cached
  bool containsUser(String userId) {
    return _cache.containsKey(userId);
  }
}
