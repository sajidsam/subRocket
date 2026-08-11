import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rocket_controller/core/models/vehicle_state.dart';
import 'package:rocket_controller/core/services/flight_logger_service.dart';
import 'package:rocket_controller/core/services/mavlink_service.dart';
import 'package:rocket_controller/core/services/parameter_service.dart';
import 'package:rocket_controller/core/services/speech_service.dart';
import 'package:rocket_controller/main.dart';

void main() {
  testWidgets('RocketGcsApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final vehicleState = VehicleState();
    final speechService = SpeechService();
    final mavlinkService = MavlinkService(vehicle: vehicleState, speech: speechService);
    final parameterService = ParameterService(vehicle: vehicleState);
    final flightLoggerService = FlightLoggerService(vehicle: vehicleState);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
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

    expect(find.byType(RocketGcsApp), findsOneWidget);

    mavlinkService.disconnectSync();
    flightLoggerService.dispose();
    await tester.pump();
  });
}
