import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/parameter_item.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/presentation/widgets/gcs_drawer.dart';
import '../../../../core/services/parameter_service.dart';

class ParameterEditorScreen extends StatelessWidget {
  const ParameterEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paramService = context.watch<ParameterService>();
    final params = paramService.filteredParameters;

    return Scaffold(
      drawer: const GcsDrawer(),
      appBar: AppBar(
        title: const Text('ARDUPILOT PARAMETERS'),
        actions: [
          if (paramService.dirtyCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: GcsColors.greenActive, foregroundColor: Colors.black),
                icon: paramService.isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.upload, size: 18),
                label: Text('WRITE (${paramService.dirtyCount})'),
                onPressed: paramService.isSaving ? null : () => paramService.saveDirtyParameters(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All to Defaults',
            onPressed: () => paramService.resetAllToDefaults(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Category Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: GcsColors.surfaceDark,
              border: Border(right: BorderSide(color: GcsColors.border, width: 1.5)),
            ),
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.list, color: GcsColors.cyanAccent, size: 20),
                  title: const Text('ALL CATEGORIES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  selected: paramService.selectedCategory == null,
                  selectedTileColor: GcsColors.surfaceCard,
                  onTap: () => paramService.setCategory(null),
                ),
                const Divider(color: GcsColors.border, height: 1),
                ...ParamCategory.values.map((cat) {
                  final isSelected = paramService.selectedCategory == cat;
                  return ListTile(
                    title: Text(cat.name, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isSelected ? GcsColors.cyanAccent : Colors.white70)),
                    selected: isSelected,
                    selectedTileColor: GcsColors.surfaceCard,
                    onTap: () => paramService.setCategory(cat),
                  );
                }),
              ],
            ),
          ),

          // Right: Search and Parameter List
          Expanded(
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  color: GcsColors.surfaceDark,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Search parameter name or description (e.g. BATT_, WPNAV_, P_GAIN)...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: GcsColors.cyanAccent),
                      isDense: true,
                      filled: true,
                      fillColor: GcsColors.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                    ),
                    onChanged: (val) => paramService.setSearchQuery(val),
                  ),
                ),

                // Parameter Cards
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: params.length,
                    itemBuilder: (context, index) {
                      final item = params[index];
                      return _buildParameterCard(context, item, paramService);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(BuildContext context, ParameterItem item, ParameterService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: item.isDirty ? GcsColors.warningOrange : GcsColors.border,
          width: item.isDirty ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Param Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: GcsColors.cyanAccent,
                        ),
                      ),
                      if (item.isDirty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: GcsColors.warningOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('MODIFIED', style: TextStyle(fontSize: 9, color: GcsColors.warningOrange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Range: ${item.min} - ${item.max} ${item.unit} | Default: ${item.defaultValue}',
                    style: const TextStyle(fontSize: 10, color: GcsColors.textSecondary, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),

            // Value Input
            SizedBox(
              width: 130,
              child: TextFormField(
                key: ValueKey(item.name + item.value.toString()),
                initialValue: item.value.toString(),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: item.isDirty ? GcsColors.warningOrange : GcsColors.greenActive,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  suffixText: item.unit,
                  suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.black45,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: item.isDirty ? GcsColors.warningOrange : Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: GcsColors.cyanAccent),
                  ),
                ),
                onFieldSubmitted: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    service.updateParamValue(item.name, parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
