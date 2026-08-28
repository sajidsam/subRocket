import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/parameter_item.dart';
import '../../../../core/presentation/theme/gcs_theme.dart';
import '../../../../core/services/parameter_service.dart';

class ParameterEditorScreen extends StatelessWidget {
  const ParameterEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paramService = context.watch<ParameterService>();
    final params = paramService.filteredParameters;

    return Scaffold(
      backgroundColor: GcsColors.frameBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: GcsColors.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GcsColors.aviationBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GcsColors.cyanAccent.withValues(alpha: 0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: GcsColors.cyanAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'PARAMETERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: GcsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ARDUPILOT EEPROM PARAMETER TREE',
              style: TextStyle(
                fontSize: 11,
                color: GcsColors.textSecondary,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          if (paramService.dirtyCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GcsColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: paramService.isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.upload, size: 16),
                label: Text('WRITE (${paramService.dirtyCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                onPressed: paramService.isSaving ? null : () => paramService.saveDirtyParameters(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: GcsColors.cyanAccent, size: 20),
            tooltip: 'Reset All to Defaults',
            onPressed: () => paramService.resetAllToDefaults(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: GcsColors.background,
        child: Row(
          children: [
            // Left: Category Sidebar
            Container(
              width: 220,
              margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              decoration: BoxDecoration(
                color: GcsColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GcsColors.border, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: paramService.selectedCategory == null ? GcsColors.surfaceCard : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: paramService.selectedCategory == null ? GcsColors.cyanAccent : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.view_list, color: paramService.selectedCategory == null ? GcsColors.goldAccent : GcsColors.textMuted, size: 18),
                      title: Text(
                        'ALL CATEGORIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: paramService.selectedCategory == null ? Colors.white : GcsColors.textSecondary,
                        ),
                      ),
                      onTap: () => paramService.setCategory(null),
                    ),
                  ),
                  const Divider(color: GcsColors.border, height: 12),
                  ...ParamCategory.values.map((cat) {
                    final isSelected = paramService.selectedCategory == cat;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? GcsColors.surfaceCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? GcsColors.cyanAccent : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.folder_outlined,
                          size: 16,
                          color: isSelected ? GcsColors.cyanAccent : GcsColors.textMuted,
                        ),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : GcsColors.textSecondary,
                          ),
                        ),
                        onTap: () => paramService.setCategory(cat),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Right: Search and Parameter List
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                decoration: BoxDecoration(
                  color: GcsColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GcsColors.border, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: GcsColors.surfaceCard,
                        border: Border(bottom: BorderSide(color: GcsColors.border)),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search parameter name or description (e.g. BATT_, WPNAV_, P_GAIN)...',
                          hintStyle: const TextStyle(color: GcsColors.textMuted, fontSize: 12, fontFamily: 'monospace'),
                          prefixIcon: const Icon(Icons.search, color: GcsColors.cyanAccent, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: GcsColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GcsColors.cyanAccent, width: 1.5)),
                        ),
                        onChanged: (val) => paramService.setSearchQuery(val),
                      ),
                    ),

                    // Parameter Cards
                    Expanded(
                      child: params.isEmpty
                          ? Center(
                              child: Text(
                                'No matching parameters found.',
                                style: TextStyle(color: GcsColors.textMuted, fontFamily: 'monospace', fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard(BuildContext context, ParameterItem item, ParameterService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: GcsColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isDirty ? GcsColors.warningOrange : GcsColors.border,
          width: item.isDirty ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12.0),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: GcsColors.cyanAccent,
                      ),
                    ),
                    if (item.isDirty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GcsColors.warningOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GcsColors.warningOrange.withValues(alpha: 0.6)),
                        ),
                        child: const Text('MODIFIED', style: TextStyle(fontSize: 8, color: GcsColors.warningOrange, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Range: ${item.min} - ${item.max} ${item.unit}',
                      style: const TextStyle(fontSize: 10, color: GcsColors.textSecondary, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: Colors.white24),
                    const SizedBox(width: 8),
                    Text(
                      'Default: ${item.defaultValue}',
                      style: const TextStyle(fontSize: 10, color: GcsColors.goldAccent, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Value Input
          SizedBox(
            width: 120,
            child: TextFormField(
              key: ValueKey(item.name + item.value.toString()),
              initialValue: item.value.toString(),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: item.isDirty ? GcsColors.warningOrange : GcsColors.greenActive,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                suffixText: item.unit,
                suffixStyle: const TextStyle(color: GcsColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
                isDense: true,
                filled: true,
                fillColor: GcsColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: item.isDirty ? GcsColors.warningOrange : GcsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: GcsColors.cyanAccent),
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
    );
  }
}
