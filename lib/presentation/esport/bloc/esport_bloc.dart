import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/firestore/esport/esport_model.dart';
import 'package:pes_arena/firebase/firestore/esport/gn_firestore_esport.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

part 'esport_event.dart';
part 'esport_state.dart';

class EsportBloc extends Bloc<EsportEvent, EsportState> {
  EsportBloc() : super(const EsportState()) {
    on<InitEsport>(_onInitEsport);
  }

  void _onInitEsport(InitEsport event, Emitter<EsportState> emit) async {
    // get data from firestore
    final models = await getIt<GNFirestore>().getEsports();
    if (models.isNotEmpty) {
      emit(state.copyWith(esportModel: models.first));
      return;
    }
  }
}
