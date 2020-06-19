import 'dart:async';

import 'package:meta/meta.dart';

import '../repositories/devices_api_client.dart';
import '../models/models.dart';

class DevicesRepository {
  final DevicesApiClient DevicesApiClient;

  DevicesRepository({@required this.DevicesApiClient})
      : assert(DevicesApiClient != null);

  Future<Devices> getDevices(String city) async {
    final int locationId = await DevicesApiClient.getLocationId(city);
    return DevicesApiClient.fetchDevices(locationId);
  }
}
