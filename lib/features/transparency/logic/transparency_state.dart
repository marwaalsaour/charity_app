import '../data/models/transparency_model.dart';

abstract class TransparencyState {}

class TransparencyInitial extends TransparencyState {}

class TransparencyLoading extends TransparencyState {}

class TransparencyLoaded extends TransparencyState {
  TransparencyLoaded(this.data);

  final TransparencyData data;
}
