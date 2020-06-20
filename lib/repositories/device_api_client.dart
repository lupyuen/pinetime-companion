//  Client API for accessing Bluetooth LE device
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import '../models/models.dart';

class DeviceApiClient {
  /// Connect to the Bluetooth LE device and list the services
  Future<Device> fetchDevice(BluetoothDevice bluetoothDevice) async {
    print('Fetching device...\n');
    //  Connect to the device
    await bluetoothDevice.connect();

    //  Discover the services
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    services.forEach((service) {
      print('${service.toString()}\n');
    });

    final device = Device(
      condition: DeviceCondition.clear,
      formattedCondition: bluetoothDevice.name, //// 'Ready for firmware update',
      minTemp: 0,
      temp: 1,
      maxTemp: 1,
      locationId: 0,
      lastUpdated: DateTime.now(),
      location: 'location',
      bluetoothDevice: bluetoothDevice
    );
    return device;
  }
}

/*
final locationUrl = '$baseUrl/api/location/search/?query=$city';
final locationResponse = await this.httpClient.get(locationUrl);
if (locationResponse.statusCode != 200) {
  throw Exception('error getting locationId for city');
}

final locationJson = jsonDecode(locationResponse.body) as List;
return (locationJson.first)['woeid'];

final DeviceUrl = '$baseUrl/api/location/$locationId';
final DeviceResponse = await this.httpClient.get(DeviceUrl);

if (DeviceResponse.statusCode != 200) {
  throw Exception('error getting Device for location');
}

final DeviceJson = jsonDecode(DeviceResponse.body);
return Device.fromJson(DeviceJson);
*/
