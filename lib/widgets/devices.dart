//  Browse Bluetooth LE Devices
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/widgets.dart';
import '../blocs/blocs.dart';

class Devices extends StatefulWidget {
  @override
  State<Devices> createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
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
                  builder: (context) => CitySelection(),
                ),
              );
              if (city != null) {
                BlocProvider.of<DevicesBloc>(context)
                    .add(DevicesRequested(city: city));
              }
            },
          )
        ],
      ),
      body: Center(
        child: BlocConsumer<DevicesBloc, DevicesState>(
          listener: (context, state) {
            if (state is DevicesLoadSuccess) {
              BlocProvider.of<ThemeBloc>(context).add(
                DevicesChanged(condition: state.devices.condition),
              );
              _refreshCompleter?.complete();
              _refreshCompleter = Completer();
            }
          },
          builder: (context, state) {
            if (state is DevicesLoadInProgress) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is DevicesLoadSuccess) {
              final devices = state.devices;

              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return GradientContainer(
                    color: themeState.color,
                    child: RefreshIndicator(
                      onRefresh: () {
                        BlocProvider.of<DevicesBloc>(context).add(
                          DevicesRefreshRequested(city: devices.location),
                        );
                        return _refreshCompleter.future;
                      },
                      child: ListView(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 100.0),
                            child: Center(
                              child: Location(location: devices.location),
                            ),
                          ),
                          Center(
                            child: LastUpdated(dateTime: devices.lastUpdated),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            /* TODO
                            child: Center(
                              child: CombinedDevicesTemperature(
                                Devices: devices,
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
            if (state is DevicesLoadFailure) {
              return Text(
                'Something went wrong!',
                style: TextStyle(color: Colors.red),
              );
            }
            return Center(child: Text('Please Select a Location'));
          },
        ),
      ),
    );
  }
}
