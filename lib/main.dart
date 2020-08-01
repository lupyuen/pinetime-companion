//  PineTime Companion App
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'simple_bloc_delegate.dart';
import 'widgets/widgets.dart';
import 'repositories/repositories.dart';
import 'blocs/blocs.dart';

void main() {
  //  Data store for browsing Bluetooth LE device
  final DeviceRepository deviceRepository = DeviceRepository(
    deviceApiClient: DeviceApiClient(),
  );

  BlocSupervisor.delegate = SimpleBlocDelegate();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),
      ],
      child: App(deviceRepository: deviceRepository),
    ),
  );
}

class App extends StatelessWidget {
  final DeviceRepository deviceRepository;

  App({Key key, @required this.deviceRepository})
      : assert(deviceRepository != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'PineTime Companion',
          theme: themeState.theme,
          home: BlocProvider(
            create: (context) => DeviceBloc(
              deviceRepository: deviceRepository,
            ),

            //  App starts with the Device widget
            child: Device(),
          ),
        );
      },
    );
  }
}
