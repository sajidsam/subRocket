import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/models/vehicle_state.dart';
import 'core/presentation/theme/gcs_theme.dart';
import 'core/services/flight_logger_service.dart';
import 'core/services/mavlink_service.dart';
import 'core/services/parameter_service.dart';
import 'core/services/speech_service.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final vehicleState = VehicleState();
  final speechService = SpeechService();
  final mavlinkService = MavlinkService(vehicle: vehicleState, speech: speechService);
  final parameterService = ParameterService(vehicle: vehicleState);
  final flightLoggerService = FlightLoggerService(vehicle: vehicleState);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vehicleState),
        Provider.value(value: speechService),
        ChangeNotifierProvider.value(value: mavlinkService),
        ChangeNotifierProvider.value(value: parameterService),
        ChangeNotifierProvider.value(value: flightLoggerService),
      ],
      child: const RocketGcsApp(),
    ),
  );
}

class RocketGcsApp extends StatelessWidget {
  const RocketGcsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAFAR GCS',
      debugShowCheckedModeBanner: false,
      theme: GcsTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
