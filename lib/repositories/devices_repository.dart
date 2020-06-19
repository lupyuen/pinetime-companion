import 'dart:async';

import 'package:meta/meta.dart';

import '../repositories/devices_api_client.dart';
import '../models/models.dart';

class DevicesRepository {
  final DevicesApiClient devicesApiClient;

  DevicesRepository({@required this.devicesApiClient})
      : assert(devicesApiClient != null);

  Future<Devices> getDevices(String city) async {
    final int locationId = await devicesApiClient.getLocationId(city);
    return devicesApiClient.fetchDevices(locationId);
  }
}
