//  Client API for browsing Bluetooth LE devices
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class DevicesApiClient {
  static const baseUrl = 'https://www.metaDevices.com';
  final http.Client httpClient;

  DevicesApiClient({@required this.httpClient}) : assert(httpClient != null);

  Future<int> getLocationId(String city) async {
    /*
    final locationUrl = '$baseUrl/api/location/search/?query=$city';
    final locationResponse = await this.httpClient.get(locationUrl);
    if (locationResponse.statusCode != 200) {
      throw Exception('error getting locationId for city');
    }

    final locationJson = jsonDecode(locationResponse.body) as List;
    return (locationJson.first)['woeid'];
    */
  }

  Future<Devices> fetchDevices(int locationId) async {
    /*
    final DevicesUrl = '$baseUrl/api/location/$locationId';
    final DevicesResponse = await this.httpClient.get(DevicesUrl);

    if (DevicesResponse.statusCode != 200) {
      throw Exception('error getting Devices for location');
    }

    final DevicesJson = jsonDecode(DevicesResponse.body);
    return Devices.fromJson(DevicesJson);
    */
  }
}
