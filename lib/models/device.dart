//  Data Model for browsing Bluetooth LE device
import 'package:equatable/equatable.dart';

enum DeviceCondition {
  snow,
  sleet,
  hail,
  thunderstorm,
  heavyRain,
  lightRain,
  showers,
  heavyCloud,
  lightCloud,
  clear,
  unknown
}

class Device extends Equatable {
  final DeviceCondition condition;
  final String formattedCondition;
  final double minTemp;
  final double temp;
  final double maxTemp;
  final int locationId;
  final String created;
  final DateTime lastUpdated;
  final String location;

  const Device({
    this.condition,
    this.formattedCondition,
    this.minTemp,
    this.temp,
    this.maxTemp,
    this.locationId,
    this.created,
    this.lastUpdated,
    this.location,
  });

  @override
  List<Object> get props => [
        condition,
        formattedCondition,
        minTemp,
        temp,
        maxTemp,
        locationId,
        created,
        lastUpdated,
        location,
      ];

  static Device fromJson(dynamic json) {
    final consolidatedDevice = json['consolidated_Device'][0];
    return Device(
      condition: _mapStringToDeviceCondition(
          consolidatedDevice['Device_state_abbr']),
      formattedCondition: consolidatedDevice['Device_state_name'],
      minTemp: consolidatedDevice['min_temp'] as double,
      temp: consolidatedDevice['the_temp'] as double,
      maxTemp: consolidatedDevice['max_temp'] as double,
      locationId: json['woeid'] as int,
      created: consolidatedDevice['created'],
      lastUpdated: DateTime.now(),
      location: json['title'],
    );
  }

  static DeviceCondition _mapStringToDeviceCondition(String input) {
    DeviceCondition state;
    switch (input) {
      case 'sn':
        state = DeviceCondition.snow;
        break;
      case 'sl':
        state = DeviceCondition.sleet;
        break;
      case 'h':
        state = DeviceCondition.hail;
        break;
      case 't':
        state = DeviceCondition.thunderstorm;
        break;
      case 'hr':
        state = DeviceCondition.heavyRain;
        break;
      case 'lr':
        state = DeviceCondition.lightRain;
        break;
      case 's':
        state = DeviceCondition.showers;
        break;
      case 'hc':
        state = DeviceCondition.heavyCloud;
        break;
      case 'lc':
        state = DeviceCondition.lightCloud;
        break;
      case 'c':
        state = DeviceCondition.clear;
        break;
      default:
        state = DeviceCondition.unknown;
    }
    return state;
  }
}
