import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

/// Thin abstraction over Firestore operations the offline→online sync flow
/// needs.
///
/// Sync ghi data online theo mô hình "build plan locally → commit 1 batch
/// atomic". Nếu batch fail, không có gì commit → không cần rollback. Plan
/// vượt giới hạn 500 ops/batch sẽ bị block ở UI trước khi gọi commitBatch.
abstract class SyncRemoteGateway {
  /// Group user hiện tại là member, dùng cho step 1.
  Future<List<GNEsportGroup>> getMyGroups();

  /// Member của 1 group, dùng cho step 2 (mapping picker).
  Future<List<GNUser>> getGroupMembers(String groupId);

  /// Commit toàn bộ plan trong 1 Firestore WriteBatch atomic. Throw nếu
  /// Firestore reject (rule, quota, network...). Nếu throw, KHÔNG có doc
  /// nào được tạo.
  Future<void> commitBatch(MigrationPlan plan);
}
