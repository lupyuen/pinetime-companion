import 'package:flutter/material.dart';

import '../blocs/blocs.dart';

class Temperature extends StatelessWidget {
  final double temperature;
  final double low;
  final double high;
  final TemperatureUnits units;

  Temperature({
    Key key,
    this.temperature,
    this.low,
    this.high,
    this.units,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /*
        Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: Text(
            '1.${_formattedTemperature(temperature)}.0',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        */
        Column(
          children: [
            Text(
              'Active Firmware: 1.${_formattedTemperature(high)}.0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w100,
                color: Colors.white,
              ),
            ),
            Text(
              'Standby Firmware: 1.${_formattedTemperature(low)}.0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w100,
                color: Colors.white,
              ),
            )
          ],
        )
      ],
    );
  }

  int _toFahrenheit(double celsius) => ((celsius * 9 / 5) + 32).round();

  int _formattedTemperature(double t) =>
      units == TemperatureUnits.fahrenheit ? _toFahrenheit(t) : t.round();
}
