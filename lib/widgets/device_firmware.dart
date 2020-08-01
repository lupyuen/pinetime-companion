//  Widget to display firmware versions in a device
import 'package:flutter/material.dart';

class DeviceFirmware extends StatelessWidget {
  final String activeFirmwareVersion;
  final String standbyFirmwareVersion;

  DeviceFirmware(
      {Key key, this.activeFirmwareVersion, this.standbyFirmwareVersion})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Active Firmware: $activeFirmwareVersion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w100,
            color: Colors.white,
          ),
        ),
        Text(
          'Standby Firmware: $standbyFirmwareVersion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w100,
            color: Colors.white,
          ),
        )
      ],
    );
  }
}
