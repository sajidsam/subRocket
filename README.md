<div align="center">

# 🛰️ SAFAR Ground Control Station (GCS)
### Tactical Telemetry, Autonomous Mission Planner & Avionics Control Suite

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform - Windows](https://img.shields.io/badge/Platform-Windows%20x64-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/sajidsam/subRocket/releases)
[![Platform - Web](https://img.shields.io/badge/Platform-Web%20%2F%20PWA-FF6F00?style=for-the-badge&logo=googlechrome&logoColor=white)](https://flutter.dev/web)
[![MAVLink Protocol](https://img.shields.io/badge/MAVLink-v2.0-22C55E?style=for-the-badge)](https://mavlink.io)
[![Release](https://img.shields.io/github/v/release/sajidsam/subRocket?style=for-the-badge&color=FA7B35)](https://github.com/sajidsam/subRocket/releases)

<br/>

**SAFAR GCS** is a tactical, high-performance Ground Control Station engineered for autonomous UAVs, rockets, and robotic platforms. Built with Flutter, it delivers a responsive dark cockpit interface featuring autonomous waypoint planning, live MAVLink telemetry streams, real-time EEPROM parameter management, and payload camera controls.

<br/>

![SAFAR GCS Mission Planner](docs/screenshots/mission_planner.png)

</div>

---

## ✨ Key Capabilities

- 🗺️ **Autonomous Mission Planning:** Visual waypoint survey grids on high-resolution satellite maps with real-time route computation, trigger intervals, and altitude reference modes (AGL / AMSL / Terrain).
- 📡 **Datalink & MAVLink Console:** Built-in SITL 6-DOF simulation engine, serial COM / UDP telemetry streams, packet health metrics (latency, loss rate, RX counter), and live system message logs.
- ⚙️ **EEPROM Parameter Tree:** Comprehensive live parameter tuning across flight sub-systems (Battery & Power, Waypoint & Nav, Attitude & PID, Failsafe & RTL, Motors & ESC, EKF & Sensors).
- 📷 **Payload & Lighting Hardware Deck:** Hardware toggles for Electronic Image Stabilization (EIS), Dynamic HDR, Thermal false-color overlay, Night Vision IR strobe, and gimbal searchlights.
- 📋 **Flight Logs & Diagnostic Alerts:** Timestamped, severity-graded event timeline (Info, Notice, Warning, Critical) with black-box session playback.
- ⚡ **Rapid Tactical Controls:** Hardware keyboard override shortcuts for emergency motor stop, throttle scaling, and roll trim.

---

## 📸 Interface Tour

### 1. Autonomous Waypoint & Survey Mission Planner
Full visual route generation with payload sensors (RGB 4K, Thermal, LiDAR), crosshatch grids, turn coordination, and live battery draw estimates.

![Mission Planner](docs/screenshots/mission_planner.png)

---

### 2. Live EEPROM Parameter Editor
Searchable parameter registry with validation ranges, unit specifications, and default reset triggers.

![Parameter Editor](docs/screenshots/parameter_editor.png)

---

### 3. Datalink Console & MAVLink Stream
Telemetry protocol selection, communication health monitor (latency, packet loss), and raw packet message logs.

![Datalink Console](docs/screenshots/datalink_console.png)

---

### 4. Camera & Lighting Control Deck
Live attitude and acceleration telemetry plots paired with camera sensor toggles and gimbal illumination controls.

![Camera and Lighting Controls](docs/screenshots/camera_lighting_controls.png)

---

### 5. System Flight Logs & Event Alerts
Chronological event logging with color-coded severity indicators for flight auditing and safety inspections.

![System Flight Logs](docs/screenshots/flight_logs_events.png)

---

## 🕹️ Keyboard Controls & Safety Shortcuts

| Shortcut | Function | Description |
| :--- | :--- | :--- |
| <kbd>Space</kbd> | **Emergency Motor Cut** | Immediate motor disarm in critical failsafe events |
| <kbd>W</kbd> / <kbd>↑</kbd> | **Throttle Up** | Increment vehicle throttle (+5%) |
| <kbd>S</kbd> / <kbd>↓</kbd> | **Throttle Down** | Decrement vehicle throttle (-5%) |
| <kbd>A</kbd> / <kbd>←</kbd> | **Roll Left** | Tactical roll trim adjustment |
| <kbd>D</kbd> / <kbd>→</kbd> | **Roll Right** | Tactical roll trim adjustment |

---

## 📥 Standalone Windows Installation (.exe)

Pre-built portable executables for 64-bit Windows are generated automatically for each release:

1. Visit the **[GitHub Releases](https://github.com/sajidsam/subRocket/releases)** page.
2. Download the latest **`SAFAR_GCS_vX.X.X_Windows_x64.zip`**.
3. Extract the ZIP archive and run `rocket_controller.exe`.

---

## 🛠️ Development & Local Build

### Requirements
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10+)
- [Git](https://git-scm.com/)

### 1. Clone & Setup
```bash
git clone https://github.com/sajidsam/subRocket.git
cd subRocket
flutter pub get
```

### 2. Launch Development Server
```bash
# Run on Windows Desktop
flutter run -d windows

# Run in Chrome / Web
flutter run -d chrome
```

### 3. Build Release
```bash
# Build standalone Windows 64-bit release
flutter build windows --release

# Or package the release ZIP with the helper script:
.\scripts\build_release_zip.ps1
```

The output will be located in: `build/windows/x64/runner/Release/`

---

## 🏛️ System Architecture

```
lib/
├── core/
│   ├── models/            # VehicleState, ParameterItem, FlightMode, LogEntry
│   ├── presentation/      # Tactical theme, HUD PFD, Status & Emergency panels
│   └── services/          # MavlinkService, ParameterService, FlightLoggerService
└── features/
    ├── dashboard/         # Cockpit viewfinder, tactical compass, drone status cards
    ├── mission_planner/   # Waypoint route planning, geofencing & payload configs
    ├── parameters/        # EEPROM parameter tree and live editor
    ├── datalink/          # Telemetry protocol selection & MAVLink packet console
    ├── calibration/       # Sensor calibration wizards (Compass, Gyro, Accel)
    ├── flight_logs/       # Blackbox flight session logger and event audits
    └── telemetry/         # High-frequency attitude, battery, and signal charts
```

---

## 📄 License

This project is licensed under the **MIT License**.
