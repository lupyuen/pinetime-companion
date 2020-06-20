//  Client API for browsing Bluetooth LE devices
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import '../models/models.dart';

class DevicesApiClient {
  Future<int> getLocationId(String city) async {
    return 0;
  }

  Future<Devices> fetchDevices(int locationId) async {
    final devices = Devices(
      condition: DevicesCondition.clear,
      formattedCondition: 'formattedCondition',
      minTemp: 0,
      temp: 50,
      maxTemp: 99,
      locationId: 0,
      lastUpdated: DateTime.now(),
      location: 'location'
    );
    return devices;
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

final DevicesUrl = '$baseUrl/api/location/$locationId';
final DevicesResponse = await this.httpClient.get(DevicesUrl);

if (DevicesResponse.statusCode != 200) {
  throw Exception('error getting Devices for location');
}

final DevicesJson = jsonDecode(DevicesResponse.body);
return Devices.fromJson(DevicesJson);
*/
