import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rocket_controller/core/models/vehicle_state.dart';
import 'package:rocket_controller/core/services/flight_logger_service.dart';
import 'package:rocket_controller/core/services/mavlink_service.dart';
import 'package:rocket_controller/core/services/parameter_service.dart';
import 'package:rocket_controller/core/services/speech_service.dart';
import 'package:rocket_controller/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:rocket_controller/features/dashboard/presentation/widgets/camera_viewfinder_card.dart';
import 'package:rocket_controller/features/dashboard/presentation/widgets/drone_status_card.dart';
import 'package:rocket_controller/features/dashboard/presentation/widgets/flight_camera_deck_card.dart';
import 'package:rocket_controller/features/dashboard/presentation/widgets/jca_sidebar.dart';
import 'package:rocket_controller/features/dashboard/presentation/widgets/tactical_compass_card.dart';

void main() {
  group('Dashboard Cockpit UI Tests', () {
    late VehicleState vehicleState;
    late SpeechService speechService;
    late MavlinkService mavlinkService;
    late ParameterService parameterService;
    late FlightLoggerService flightLoggerService;

    setUp(() {
      vehicleState = VehicleState();
      speechService = SpeechService();
      mavlinkService = MavlinkService(vehicle: vehicleState, speech: speechService);
      parameterService = ParameterService(vehicle: vehicleState);
      flightLoggerService = FlightLoggerService(vehicle: vehicleState);
    });

    tearDown(() {
      mavlinkService.disconnectSync();
      flightLoggerService.dispose();
    });

    Widget createTestableWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vehicleState),
          Provider.value(value: speechService),
          ChangeNotifierProvider.value(value: mavlinkService),
          ChangeNotifierProvider.value(value: parameterService),
          ChangeNotifierProvider.value(value: flightLoggerService),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('Dashboard renders all 5 core cockpit modules', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const DashboardScreen()));
      await tester.pump();

      expect(find.byType(JcaSidebar), findsOneWidget);
      expect(find.byType(CameraViewfinderCard), findsOneWidget);
      expect(find.byType(FlightCameraDeckCard), findsOneWidget);
      expect(find.byType(DroneStatusCard), findsOneWidget);
      expect(find.byType(TacticalCompassCard), findsAtLeastNWidgets(1));
      expect(find.text('JCA'), findsOneWidget);
      expect(find.text('4K . 19.67FPS'), findsOneWidget);
      expect(find.text('DJI Mavic pro'), findsOneWidget);
      expect(find.text('83°'), findsAtLeastNWidgets(1));
    });

    testWidgets('CameraViewfinderCard toggles HDR and Pause states', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const CameraViewfinderCard()));
      await tester.pump();

      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('H2.85'), findsOneWidget);

      await tester.tap(find.text('HDR'));
      await tester.pump();

      expect(find.text('HDR'), findsOneWidget);
    });

    testWidgets('FlightCameraDeckCard toggles video/photo and resolution lines', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const FlightCameraDeckCard()));
      await tester.pump();

      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('1280 : 720'), findsOneWidget);
      expect(find.text('1920 : 1080'), findsOneWidget);

      await tester.tap(find.text('Photo'));
      await tester.pump();

      await tester.tap(find.text('1920 : 1080'));
      await tester.pump();
    });

    testWidgets('DroneStatusCard displays battery and responds to sliders', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const DroneStatusCard()));
      await tester.pump();

      expect(find.text('DJI Mavic pro'), findsOneWidget);
      expect(find.text('Battery status'), findsOneWidget);
      expect(find.text('Altitude limited'), findsOneWidget);
      expect(find.text('HDR+'), findsOneWidget);
    });

    testWidgets('TacticalCompassCard formats coordinates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const TacticalCompassCard()));
      await tester.pump();

      expect(find.text('83°'), findsOneWidget);
      expect(find.byType(TacticalCompassCard), findsOneWidget);
    });

    testWidgets('JcaSidebar switches outlet content while sidebar remains fixed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const DashboardScreen()));
      await tester.pump();

      // Starts on Cockpit Home View (index 0)
      expect(find.byType(JcaSidebar), findsOneWidget);
      expect(find.byType(CameraViewfinderCard), findsOneWidget);

      // Tap Target Tracking icon (gps_fixed, index 1)
      await tester.tap(find.byIcon(Icons.gps_fixed));
      await tester.pump(const Duration(milliseconds: 600));

      // JcaSidebar is still present and fixed
      expect(find.byType(JcaSidebar), findsOneWidget);
      // Target tracking view is now loaded in the outlet
      expect(find.byType(CameraViewfinderCard), findsNothing);

      // Tap JCA badge or Cockpit icon to return home
      await tester.tap(find.text('JCA'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(JcaSidebar), findsOneWidget);
      expect(find.byType(CameraViewfinderCard), findsOneWidget);
    });
  });
}
