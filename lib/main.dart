//  PineTime Companion App
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'simple_bloc_delegate.dart';
import 'widgets/widgets.dart';
import 'repositories/repositories.dart';
import 'blocs/blocs.dart';

void main() {
  final DevicesRepository devicesRepository = DevicesRepository(
    devicesApiClient: DevicesApiClient(),
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

      child: App(
        devicesRepository: devicesRepository
      ),
    ),
  );
}

class App extends StatelessWidget {
  final DevicesRepository devicesRepository;

  App({Key key, @required this.devicesRepository})
      : assert(devicesRepository != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'PineTime Companion',
          theme: themeState.theme,

          home: BlocProvider(
            create: (context) => DevicesBloc(
              devicesRepository: devicesRepository,
            ),

            //  App starts with the Devices widget
            child: Devices(),
          ),

        );
      },
    );
  }
}
