import 'package:flutter/material.dart';
import 'agri_theme_constants.dart';

class AgriMapToolbar extends StatelessWidget {
  final bool isSatellite;
  final VoidCallback onToggleMapType;
  final VoidCallback onCenterHome;
  final VoidCallback onGenerateSurveyGrid;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClearAll;

  const AgriMapToolbar({
    super.key,
    required this.isSatellite,
    required this.onToggleMapType,
    required this.onCenterHome,
    required this.onGenerateSurveyGrid,
    required this.onToggleFullscreen,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AgriColors.headerBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AgriColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolButton(
            icon: Icons.edit_outlined,
            tooltip: 'Tap map to add waypoints',
            isActive: true,
            onTap: () {},
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.grid_on_rounded,
            tooltip: 'Generate Auto Survey Grid',
            isActive: false,
            onTap: onGenerateSurveyGrid,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Center on Vehicle / Home',
            isActive: false,
            onTap: onCenterHome,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: isSatellite ? Icons.satellite_alt_rounded : Icons.map_outlined,
            tooltip: isSatellite ? 'Switch to Standard Map' : 'Switch to Satellite Imagery',
            isActive: isSatellite,
            onTap: onToggleMapType,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.fullscreen_rounded,
            tooltip: 'Fit Mission Bounds',
            isActive: false,
            onTap: onToggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AgriColors.orangeSubtle : AgriColors.cardElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? AgriColors.orangePrimary.withValues(alpha: 0.6) : AgriColors.borderLight,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? AgriColors.orangePrimary : AgriColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
