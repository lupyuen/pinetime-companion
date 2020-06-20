//  Widget to browse Bluetooth LE Device
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/widgets.dart';
import '../blocs/blocs.dart';

class Device extends StatefulWidget {
  @override
  State<Device> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  Completer<void> _refreshCompleter;

  @override
  void initState() {
    super.initState();
    _refreshCompleter = Completer<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PineTime Companion'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final city = await Navigator.push(
                context,
                MaterialPageRoute(
                  //  Browse Bluetooth LE devices
                  builder: (context) => FindDevice(),
                ),
              );
              if (city != null) {
                BlocProvider.of<DeviceBloc>(context)
                    .add(DeviceRequested(city: city));
              }
            },
          )
        ],
      ),
      body: Center(
        child: BlocConsumer<DeviceBloc, DeviceState>(
          listener: (context, state) {
            if (state is DeviceLoadSuccess) {
              BlocProvider.of<ThemeBloc>(context).add(
                DeviceChanged(condition: state.device.condition),
              );
              _refreshCompleter?.complete();
              _refreshCompleter = Completer();
            }
          },
          builder: (context, state) {
            if (state is DeviceLoadInProgress) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is DeviceLoadSuccess) {
              final device = state.device;

              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return GradientContainer(
                    color: themeState.color,
                    child: RefreshIndicator(
                      onRefresh: () {
                        BlocProvider.of<DeviceBloc>(context).add(
                          DeviceRefreshRequested(city: device.location),
                        );
                        return _refreshCompleter.future;
                      },
                      child: ListView(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 100.0),
                            child: Center(
                              child: Location(location: device.location),
                            ),
                          ),
                          Center(
                            child: LastUpdated(dateTime: device.lastUpdated),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            /* TODO
                            child: Center(
                              child: CombinedDeviceTemperature(
                                Device: device,
                              ),
                            ),
                            */
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            if (state is DeviceLoadFailure) {
              return Text(
                'Something went wrong!',
                style: TextStyle(color: Colors.red),
              );
            }
            return Center(child: Text('Please Select Your PineTime'));
          },
        ),
      ),
    );
  }
}
