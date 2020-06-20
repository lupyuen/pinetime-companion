//  Widget that displays device summary
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../models/models.dart' as model;
import '../widgets/widgets.dart';

class DeviceSummary extends StatelessWidget {
  final model.Device device;

  DeviceSummary({
    Key key,
    @required this.device,
  })  : assert(device != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Image.asset('assets/pinetime.png'),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return Temperature(
                    temperature: device.temp,
                    high: device.maxTemp,
                    low: device.minTemp,
                    units: state.temperatureUnits,
                  );
                },
              ),
            ),
          ],
        ),
        Center(
          child: Text(
            device.formattedCondition,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w200,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
