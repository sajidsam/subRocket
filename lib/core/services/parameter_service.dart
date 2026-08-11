import 'package:flutter/foundation.dart';
import '../models/parameter_item.dart';
import '../models/vehicle_state.dart';

class ParameterService extends ChangeNotifier {
  final VehicleState vehicle;

  List<ParameterItem> parameters = [];
  String searchQuery = '';
  ParamCategory? selectedCategory;
  bool isSaving = false;

  ParameterService({required this.vehicle}) {
    _initDefaultParameters();
  }

  void _initDefaultParameters() {
    parameters = [
      // Battery
      ParameterItem(
        name: 'BATT_CAPACITY',
        value: 5200.0,
        defaultValue: 5200.0,
        min: 500.0,
        max: 50000.0,
        unit: 'mAh',
        description: 'Total battery capacity in milliampere-hours',
        category: ParamCategory.battery,
      ),
      ParameterItem(
        name: 'BATT_LOW_VOLT',
        value: 14.0,
        defaultValue: 14.0,
        min: 10.0,
        max: 25.0,
        unit: 'V',
        description: 'Low battery failsafe voltage threshold (triggers RTL/Land)',
        category: ParamCategory.battery,
      ),
      ParameterItem(
        name: 'BATT_CRT_VOLT',
        value: 13.4,
        defaultValue: 13.4,
        min: 9.0,
        max: 24.0,
        unit: 'V',
        description: 'Critical battery voltage threshold (triggers immediate Land)',
        category: ParamCategory.battery,
      ),
      ParameterItem(
        name: 'BATT_LOW_MAH',
        value: 1000.0,
        defaultValue: 1000.0,
        min: 100.0,
        max: 10000.0,
        unit: 'mAh',
        description: 'Low battery remaining capacity threshold',
        category: ParamCategory.battery,
      ),

      // Waypoint & Navigation
      ParameterItem(
        name: 'WPNAV_SPEED',
        value: 15.0,
        defaultValue: 15.0,
        min: 1.0,
        max: 50.0,
        unit: 'm/s',
        description: 'Autonomous mission default horizontal cruise speed',
        category: ParamCategory.navigation,
      ),
      ParameterItem(
        name: 'WPNAV_SPEED_UP',
        value: 4.0,
        defaultValue: 4.0,
        min: 0.5,
        max: 15.0,
        unit: 'm/s',
        description: 'Maximum autonomous climb rate speed',
        category: ParamCategory.navigation,
      ),
      ParameterItem(
        name: 'WPNAV_SPEED_DN',
        value: 2.5,
        defaultValue: 2.5,
        min: 0.5,
        max: 10.0,
        unit: 'm/s',
        description: 'Maximum autonomous descent rate speed',
        category: ParamCategory.navigation,
      ),
      ParameterItem(
        name: 'WPNAV_ACCEL',
        value: 2.5,
        defaultValue: 2.5,
        min: 0.5,
        max: 10.0,
        unit: 'm/s²',
        description: 'Horizontal waypoint navigation acceleration',
        category: ParamCategory.navigation,
      ),
      ParameterItem(
        name: 'WPNAV_RADIUS',
        value: 5.0,
        defaultValue: 5.0,
        min: 1.0,
        max: 30.0,
        unit: 'm',
        description: 'Waypoint acceptance radius for mission advancement',
        category: ParamCategory.navigation,
      ),

      // Attitude & PIDs
      ParameterItem(
        name: 'ATC_RAT_RLL_P',
        value: 0.135,
        defaultValue: 0.135,
        min: 0.01,
        max: 1.0,
        unit: '',
        description: 'Roll angular rate proportional gain (P)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_RLL_I',
        value: 0.090,
        defaultValue: 0.090,
        min: 0.01,
        max: 1.0,
        unit: '',
        description: 'Roll angular rate integral gain (I)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_RLL_D',
        value: 0.0036,
        defaultValue: 0.0036,
        min: 0.0001,
        max: 0.1,
        unit: '',
        description: 'Roll angular rate derivative gain (D)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_PIT_P',
        value: 0.140,
        defaultValue: 0.140,
        min: 0.01,
        max: 1.0,
        unit: '',
        description: 'Pitch angular rate proportional gain (P)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_PIT_I',
        value: 0.095,
        defaultValue: 0.095,
        min: 0.01,
        max: 1.0,
        unit: '',
        description: 'Pitch angular rate integral gain (I)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_PIT_D',
        value: 0.0038,
        defaultValue: 0.0038,
        min: 0.0001,
        max: 0.1,
        unit: '',
        description: 'Pitch angular rate derivative gain (D)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_RAT_YAW_P',
        value: 0.180,
        defaultValue: 0.180,
        min: 0.01,
        max: 1.0,
        unit: '',
        description: 'Yaw angular rate proportional gain (P)',
        category: ParamCategory.attitude,
      ),
      ParameterItem(
        name: 'ATC_ANG_RLL_P',
        value: 4.5,
        defaultValue: 4.5,
        min: 1.0,
        max: 15.0,
        unit: '',
        description: 'Roll angle response aggressiveness',
        category: ParamCategory.attitude,
      ),

      // Failsafe & RTL
      ParameterItem(
        name: 'RTL_ALT',
        value: 50.0,
        defaultValue: 50.0,
        min: 10.0,
        max: 300.0,
        unit: 'm',
        description: 'Return to Launch safety altitude (climbs if below)',
        category: ParamCategory.failsafe,
      ),
      ParameterItem(
        name: 'RTL_LOIT_TIME',
        value: 5.0,
        defaultValue: 5.0,
        min: 0.0,
        max: 60.0,
        unit: 's',
        description: 'Loiter hover duration above home before landing',
        category: ParamCategory.failsafe,
      ),
      ParameterItem(
        name: 'FS_GCS_ENABLE',
        value: 1.0,
        defaultValue: 1.0,
        min: 0.0,
        max: 3.0,
        unit: '',
        description: 'Ground Control Station telemetry datalink failsafe action',
        category: ParamCategory.failsafe,
      ),
      ParameterItem(
        name: 'FS_THR_ENABLE',
        value: 1.0,
        defaultValue: 1.0,
        min: 0.0,
        max: 3.0,
        unit: '',
        description: 'Radio transmitter loss failsafe action',
        category: ParamCategory.failsafe,
      ),

      // Motors & ESC
      ParameterItem(
        name: 'MOT_PWM_MIN',
        value: 1000.0,
        defaultValue: 1000.0,
        min: 800.0,
        max: 1200.0,
        unit: 'µs',
        description: 'Minimum motor pulse-width modulation output',
        category: ParamCategory.motors,
      ),
      ParameterItem(
        name: 'MOT_PWM_MAX',
        value: 2000.0,
        defaultValue: 2000.0,
        min: 1800.0,
        max: 2200.0,
        unit: 'µs',
        description: 'Maximum motor pulse-width modulation output',
        category: ParamCategory.motors,
      ),
      ParameterItem(
        name: 'MOT_SPIN_ARM',
        value: 0.15,
        defaultValue: 0.15,
        min: 0.0,
        max: 0.4,
        unit: '%',
        description: 'Motor idle spin speed immediately upon arming',
        category: ParamCategory.motors,
      ),

      // EKF & Sensors
      ParameterItem(
        name: 'EK3_ENABLE',
        value: 1.0,
        defaultValue: 1.0,
        min: 0.0,
        max: 1.0,
        unit: '',
        description: 'Enable Extended Kalman Filter 3 for sensor fusion',
        category: ParamCategory.sensors,
      ),
      ParameterItem(
        name: 'COMPASS_ENABLE',
        value: 1.0,
        defaultValue: 1.0,
        min: 0.0,
        max: 1.0,
        unit: '',
        description: 'Enable primary digital magnetometer',
        category: ParamCategory.sensors,
      ),
    ];
  }

  List<ParameterItem> get filteredParameters {
    return parameters.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null || p.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get dirtyCount => parameters.where((p) => p.isDirty).length;

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(ParamCategory? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void updateParamValue(String name, double newValue) {
    final idx = parameters.indexWhere((p) => p.name == name);
    if (idx != -1) {
      parameters[idx].updateValue(newValue);
      notifyListeners();
    }
  }

  Future<void> saveDirtyParameters() async {
    isSaving = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    for (var p in parameters) {
      if (p.isDirty) {
        p.isDirty = false;
      }
    }

    vehicle.addStatusMessage('Parameters synchronized to vehicle successfully', severity: SeverityLevel.info);
    isSaving = false;
    notifyListeners();
  }

  void resetAllToDefaults() {
    for (var p in parameters) {
      p.value = p.defaultValue;
      p.isDirty = false;
    }
    vehicle.addStatusMessage('Parameters reset to default values', severity: SeverityLevel.notice);
    notifyListeners();
  }
}
