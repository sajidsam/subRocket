import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rocket_controller/core/models/vehicle_state.dart';
import 'package:rocket_controller/core/services/flight_logger_service.dart';
import 'package:rocket_controller/core/services/mavlink_service.dart';
import 'package:rocket_controller/core/services/parameter_service.dart';
import 'package:rocket_controller/core/services/speech_service.dart';
import 'package:rocket_controller/features/mission_planner/presentation/screens/mission_planner_screen.dart';
import 'package:rocket_controller/features/mission_planner/presentation/widgets/agri_survey_dashboard.dart';
import 'package:rocket_controller/features/mission_planner/presentation/widgets/agri_task_sidebar.dart';
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

  testWidgets('MissionPlannerScreen renders universal drone UI and opens tabs without header bar', (WidgetTester tester) async {
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
        child: const MaterialApp(
          home: MissionPlannerScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Mission Planner widgets
    expect(find.byType(MissionPlannerScreen), findsOneWidget);
    expect(find.byType(AgriSurveyDashboard), findsOneWidget);
    expect(find.byType(AgriTaskSidebar), findsOneWidget);

    // Verify universal drone mission labels
    expect(find.textContaining('Mission Plan'), findsOneWidget);
    expect(find.text('Universal UAV Navigation'), findsOneWidget);
    expect(find.text('RGB 4K'), findsOneWidget);
    expect(find.text('Thermal'), findsOneWidget);
    expect(find.text('LiDAR'), findsOneWidget);
    expect(find.text('AGL'), findsOneWidget);

    // Switch to Task / Config tab
    await tester.tap(find.text('Task / Config'));
    await tester.pump();

    expect(find.text('Mission Profile Pattern'), findsOneWidget);
    expect(find.text('Cruise Speed (m/s)'), findsOneWidget);
    expect(find.text('Default Altitude AGL (m)'), findsOneWidget);

    mavlinkService.disconnectSync();
    flightLoggerService.dispose();
  });
}
