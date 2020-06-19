import 'dart:async';

import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../repositories/repositories.dart';
import '../models/models.dart';

abstract class DevicesEvent extends Equatable {
  const DevicesEvent();
}

class DevicesRequested extends DevicesEvent {
  final String city;

  const DevicesRequested({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

class DevicesRefreshRequested extends DevicesEvent {
  final String city;

  const DevicesRefreshRequested({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

abstract class DevicesState extends Equatable {
  const DevicesState();

  @override
  List<Object> get props => [];
}

class DevicesInitial extends DevicesState {}

class DevicesLoadInProgress extends DevicesState {}

class DevicesLoadSuccess extends DevicesState {
  final Devices devices;

  const DevicesLoadSuccess({@required this.devices}) : assert(devices != null);

  @override
  List<Object> get props => [Devices];
}

class DevicesLoadFailure extends DevicesState {}

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final DevicesRepository devicesRepository;

  DevicesBloc({@required this.devicesRepository})
      : assert(devicesRepository != null);

  @override
  DevicesState get initialState => DevicesInitial();

  @override
  Stream<DevicesState> mapEventToState(DevicesEvent event) async* {
    if (event is DevicesRequested) {
      yield* _mapDevicesRequestedToState(event);
    } else if (event is DevicesRefreshRequested) {
      yield* _mapDevicesRefreshRequestedToState(event);
    }
  }

  Stream<DevicesState> _mapDevicesRequestedToState(
    DevicesRequested event,
  ) async* {
    yield DevicesLoadInProgress();
    try {
      final Devices devices = await DevicesRepository.getDevices(event.city);
      yield DevicesLoadSuccess(devices: devices);
    } catch (_) {
      yield DevicesLoadFailure();
    }
  }

  Stream<DevicesState> _mapDevicesRefreshRequestedToState(
    DevicesRefreshRequested event,
  ) async* {
    try {
      final Devices devices = await DevicesRepository.getDevices(event.city);
      yield DevicesLoadSuccess(devices: devices);
    } catch (_) {
      yield state;
    }
  }
}
