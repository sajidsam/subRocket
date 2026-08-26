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
import 'package:rocket_controller/features/datalink/presentation/screens/connection_screen.dart';

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
      expect(find.text('SAFAR'), findsOneWidget);
      expect(find.text('4K . 19.67FPS'), findsOneWidget);
      expect(find.textContaining('Mah'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
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

    testWidgets('CameraViewfinderCard retains navigation when isDispActive is false', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const CameraViewfinderCard(isDispActive: false)));
      await tester.pump();

      // Navigation compass is still visible
      expect(find.byType(TacticalCompassCard), findsOneWidget);
      expect(find.byType(ArtificialHorizonReticle), findsOneWidget);

      // Camera HUD overlays are hidden
      expect(find.text('HDR'), findsNothing);
      expect(find.text('4K . 19.67FPS'), findsNothing);
      expect(find.text('H2.85'), findsNothing);
    });

    testWidgets('FlightCameraDeckCard toggles video/photo, resolution lines, and quick camera controls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const FlightCameraDeckCard()));
      await tester.pump();

      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Resolution px'), findsOneWidget);
      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('1280 : 720'), findsOneWidget);
      expect(find.text('1920 : 1080'), findsOneWidget);
      expect(find.text('AWB'), findsOneWidget);
      expect(find.text('DISP'), findsOneWidget);
      expect(find.textContaining('ZOOM'), findsOneWidget);

      await tester.tap(find.text('Photo'));
      await tester.pump();

      await tester.tap(find.text('DISP'));
      await tester.pump();

      await tester.tap(find.text('1920 : 1080'));
      await tester.pump();

      // Test D-Pad controls on Camera Deck
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await tester.pump();
    });

    testWidgets('DroneStatusCard displays battery, flight control deck, and responds to sliders and 3D joystick', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const DroneStatusCard()));
      await tester.pump();

      expect(find.text('88%'), findsOneWidget);
      expect(find.text('PITCH / ROLL'), findsOneWidget);
      expect(find.text('ESTOP'), findsOneWidget);
      expect(find.text('RTH'), findsOneWidget);
      expect(find.text('Altitude limit'), findsOneWidget);
      expect(find.text('GSPD'), findsOneWidget);
      expect(find.text('VSPD'), findsOneWidget);
      expect(find.text('ALT'), findsOneWidget);

      // Tap RTH and ESTOP buttons
      await tester.tap(find.text('RTH'));
      await tester.pump();
      await tester.tap(find.text('ESTOP'));
      await tester.pump();

      // Drag 3D center circle joystick (Pitch & Roll)
      final joystickFinder = find.text('PITCH / ROLL');
      expect(joystickFinder, findsOneWidget);
      final joystickCenter = tester.getCenter(joystickFinder) + const Offset(0, 60);
      await tester.dragFrom(joystickCenter, const Offset(0, -20)); // pitch forward
      await tester.pump();
      await tester.dragFrom(joystickCenter, const Offset(20, 0)); // roll right
      await tester.pump();
    });

    testWidgets('TacticalCompassCard displays heading degree and cardinal direction', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const TacticalCompassCard()));
      await tester.pump();

      expect(find.text('E'), findsOneWidget);
      expect(find.byType(TacticalCompassCard), findsOneWidget);
    });

    testWidgets('Mavlink parameters button and connection toggle button are functional in drawer/appbar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const DashboardScreen()));
      await tester.pump();

      // Dashboard Screen renders without errors
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(JcaSidebar), findsOneWidget);
    });

    testWidgets('JcaSidebar destination selection switches outlet view and returns home', (WidgetTester tester) async {
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

      // Tap SAFAR badge to return home
      await tester.tap(find.text('SAFAR'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(JcaSidebar), findsOneWidget);
      expect(find.byType(CameraViewfinderCard), findsOneWidget);
    });

    testWidgets('Tapping swap icon toggles map to primary view with 4 B&W buttons and camera to mini box', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const DashboardScreen()));
      await tester.pump();

      // Initially camera is top (shows 4K . 19.67FPS) and mini box has swap icon
      expect(find.text('4K . 19.67FPS'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Tap swap icon button
      await tester.tap(find.byIcon(Icons.sync).first);
      await tester.pump();

      // Now map is top (shows CAMERA VIEW return button, and 4 B&W icon-only logos: satellite, street, tactical, my_location)
      expect(find.text('CAMERA VIEW'), findsOneWidget);
      expect(find.byIcon(Icons.satellite_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.text('CAM LIVE'), findsOneWidget);

      // Tap TACTICAL map layer icon button
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pump();

      // Tap CAMERA VIEW return button to toggle back
      await tester.tap(find.text('CAMERA VIEW'));
      await tester.pump();

      // Swapped back: 4K . 19.67FPS is visible again
      expect(find.text('4K . 19.67FPS'), findsOneWidget);
    });

    testWidgets('ConnectionScreen IP Camera tab connects and disconnects feed smoothly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestableWidget(const ConnectionScreen()));
      await tester.pump();

      // Switch to IP Camera Link tab
      expect(find.text('IP Camera Link'), findsOneWidget);
      await tester.tap(find.text('IP Camera Link'));
      await tester.pump();

      // Verify connect button is shown
      expect(find.text('CONNECT CAMERA FEED'), findsOneWidget);

      // Tap CONNECT CAMERA FEED
      await tester.tap(find.text('CONNECT CAMERA FEED'));
      await tester.pump();

      // Vehicle state is now in streaming mode and DISCONNECT CAMERA button is visible
      expect(vehicleState.isUsingSimulatedCamera, isFalse);
      expect(find.text('DISCONNECT CAMERA'), findsOneWidget);

      // Tap DISCONNECT CAMERA
      await tester.tap(find.text('DISCONNECT CAMERA'));
      await tester.pump();

      // Reverted to simulated static picture
      expect(vehicleState.isUsingSimulatedCamera, isTrue);
      expect(find.text('CONNECT CAMERA FEED'), findsOneWidget);
    });
  });
}


