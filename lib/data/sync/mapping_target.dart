import 'package:equatable/equatable.dart';

/// Mapping target for an offline player → online identity, picked by the user
/// in step 2 of the sync flow.
sealed class MappingTarget extends Equatable {
  const MappingTarget();
}

class MapToExisting extends MappingTarget {
  const MapToExisting(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

class CreatePlaceholder extends MappingTarget {
  const CreatePlaceholder(this.displayName);
  final String displayName;

  @override
  List<Object?> get props => [displayName];
}
