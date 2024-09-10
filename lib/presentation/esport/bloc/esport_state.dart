part of 'esport_bloc.dart';

class EsportState extends Equatable {
  final EsportModel? esportModel;

  const EsportState({this.esportModel});

  EsportState copyWith({EsportModel? esportModel}) {
    return EsportState(esportModel: esportModel ?? this.esportModel);
  }

  @override
  List<Object?> get props => [esportModel];
}
