import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/transparency_model.dart';
import '../data/repositories/transparency_repository.dart';
import 'transparency_state.dart';

class TransparencyCubit extends Cubit<TransparencyState> {
  TransparencyCubit({TransparencyRepository? repository})
    : _repository = repository ?? TransparencyRepository(),
      super(TransparencyInitial());

  final TransparencyRepository _repository;
  bool _loading = false;

  Future<void> load({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    if (state is! TransparencyLoaded) {
      emit(TransparencyLoading());
    }

    try {
      final data = await _repository.fetch();
      emit(TransparencyLoaded(data));
    } catch (_) {
      if (state is! TransparencyLoaded) {
        emit(TransparencyLoaded(TransparencyData.empty));
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> refresh() => load(force: true);
}
