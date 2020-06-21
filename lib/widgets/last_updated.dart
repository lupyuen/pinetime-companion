import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../models/models.dart';

class LastUpdated extends StatelessWidget {
  final Device device;

  LastUpdated({Key key, @required this.device})
      : assert(device != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${device.location}',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w200,
        color: Colors.white,
      ),
    );
  }
}
