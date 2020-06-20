//  Data Model for browsing Bluetooth LE devices
import 'package:equatable/equatable.dart';

enum DevicesCondition {
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

class Devices extends Equatable {
  final DevicesCondition condition;
  final String formattedCondition;
  final double minTemp;
  final double temp;
  final double maxTemp;
  final int locationId;
  final String created;
  final DateTime lastUpdated;
  final String location;

  const Devices({
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

  static Devices fromJson(dynamic json) {
    final consolidatedDevices = json['consolidated_Devices'][0];
    return Devices(
      condition: _mapStringToDevicesCondition(
          consolidatedDevices['Devices_state_abbr']),
      formattedCondition: 'Lockdown No More Yay!', //// consolidatedDevices['Devices_state_name'],
      minTemp: consolidatedDevices['min_temp'] as double,
      temp: consolidatedDevices['the_temp'] as double,
      maxTemp: consolidatedDevices['max_temp'] as double,
      locationId: json['woeid'] as int,
      created: consolidatedDevices['created'],
      lastUpdated: DateTime.now(),
      location: json['title'],
    );
  }

  static DevicesCondition _mapStringToDevicesCondition(String input) {
    DevicesCondition state;
    switch (input) {
      case 'sn':
        state = DevicesCondition.snow;
        break;
      case 'sl':
        state = DevicesCondition.sleet;
        break;
      case 'h':
        state = DevicesCondition.hail;
        break;
      case 't':
        state = DevicesCondition.thunderstorm;
        break;
      case 'hr':
        state = DevicesCondition.heavyRain;
        break;
      case 'lr':
        state = DevicesCondition.lightRain;
        break;
      case 's':
        state = DevicesCondition.showers;
        break;
      case 'hc':
        state = DevicesCondition.heavyCloud;
        break;
      case 'lc':
        state = DevicesCondition.lightCloud;
        break;
      case 'c':
        state = DevicesCondition.clear;
        break;
      default:
        state = DevicesCondition.unknown;
    }
    return state;
  }
}
