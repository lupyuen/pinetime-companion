//  Business Logic for browsing Bluetooth LE device
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repositories/repositories.dart';
import '../models/models.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();
}

class DeviceRequested extends DeviceEvent {
  final String city;

  const DeviceRequested({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

class DeviceRefreshRequested extends DeviceEvent {
  final String city;

  const DeviceRefreshRequested({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object> get props => [];
}

class DeviceInitial extends DeviceState {}

class DeviceLoadInProgress extends DeviceState {}

class DeviceLoadSuccess extends DeviceState {
  final Device device;

  const DeviceLoadSuccess({@required this.device}) : assert(device != null);

  @override
  List<Object> get props => [Device];
}

class DeviceLoadFailure extends DeviceState {}

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository deviceRepository;

  DeviceBloc({@required this.deviceRepository})
      : assert(deviceRepository != null);

  @override
  DeviceState get initialState => DeviceInitial();

  @override
  Stream<DeviceState> mapEventToState(DeviceEvent event) async* {
    if (event is DeviceRequested) {
      yield* _mapDeviceRequestedToState(event);
    } else if (event is DeviceRefreshRequested) {
      yield* _mapDeviceRefreshRequestedToState(event);
    }
  }

  Stream<DeviceState> _mapDeviceRequestedToState(
    DeviceRequested event,
  ) async* {
    yield DeviceLoadInProgress();
    try {
      final Device device = await deviceRepository.getDevice(event.city);
      yield DeviceLoadSuccess(device: device);
    } catch (_) {
      yield DeviceLoadFailure();
    }
  }

  Stream<DeviceState> _mapDeviceRefreshRequestedToState(
    DeviceRefreshRequested event,
  ) async* {
    try {
      final Device device = await deviceRepository.getDevice(event.city);
      yield DeviceLoadSuccess(device: device);
    } catch (_) {
      yield state;
    }
  }
}
