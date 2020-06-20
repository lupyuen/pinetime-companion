//  Data Store for browsing Bluetooth LE device
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../repositories/device_api_client.dart';
import '../models/models.dart';

class DeviceRepository {
  final DeviceApiClient deviceApiClient;

  DeviceRepository({@required this.deviceApiClient})
      : assert(deviceApiClient != null);

  Future<Device> getDevice(BluetoothDevice device) async {
    return deviceApiClient.fetchDevice(device);
  }
}
