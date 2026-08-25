import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/squad_remote_datasource.dart';
import 'squad_event.dart';
import 'squad_state.dart';

class SquadBloc extends Bloc<SquadEvent, SquadState> {
  final SquadRemoteDatasource remoteDatasource;

  SquadBloc({required this.remoteDatasource}) : super(SquadInitialState()) {
    on<CreateSquadEvent>(_onCreateSquad);
    on<JoinSquadEvent>(_onJoinSquad);
    on<LeaveSquadEvent>(_onLeaveSquad);
  }

  Future<void> _onCreateSquad(CreateSquadEvent event, Emitter<SquadState> emit) async {
    emit(SquadLoadingState());
    try {
      final squad = await remoteDatasource.createSquad(event.title);
      emit(SquadActiveState(squad: squad));
    } catch (e) {
      emit(SquadFailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onJoinSquad(JoinSquadEvent event, Emitter<SquadState> emit) async {
    emit(SquadLoadingState());
    try {
      final squad = await remoteDatasource.joinSquad(event.squadCode);
      emit(SquadActiveState(squad: squad));
    } catch (e) {
      emit(SquadFailureState(errorMessage: e.toString()));
    }
  }

  void _onLeaveSquad(LeaveSquadEvent event, Emitter<SquadState> emit) {
    emit(SquadInitialState());
  }
}
