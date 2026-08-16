import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/provider/child_selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChildSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> availableChildren;
  final List<Map<String, dynamic>>? selectedChildren;
  final ValueChanged<List<Map<String, dynamic>>> onChildrenSelected;

  const ChildSelectionWidget({
    super.key,
    required this.availableChildren,
    this.selectedChildren,
    required this.onChildrenSelected,
  });

  @override
  State<ChildSelectionWidget> createState() => _ChildSelectionWidgetState();
}

class _ChildSelectionWidgetState extends State<ChildSelectionWidget> {
  late final ChildSelectionProvider _selectionProvider;

  @override
  void initState() {
    super.initState();
    _selectionProvider = ChildSelectionProvider(
      initialSelectedChildren: widget.selectedChildren,
    );
  }

  @override
  void dispose() {
    _selectionProvider.dispose();
    super.dispose();
  }

  void _toggleChild(Map<String, dynamic> child) {
    _selectionProvider.toggleChild(child);
    widget.onChildrenSelected(_selectionProvider.selectedChildren.toList());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChildSelectionProvider>.value(
      value: _selectionProvider,
      child: Consumer<ChildSelectionProvider>(
        builder: (context, selectionProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Anak-Anak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Config.textHead,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.availableChildren.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Config.accent),
                    borderRadius: BorderRadius.circular(8),
                    color: Config.background,
                  ),
                  child: const Center(
                    child: Text(
                      'Tidak ada anggota keluarga yang tersedia',
                      style: TextStyle(
                        color: Config.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Config.accent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.availableChildren.length,
                    itemBuilder: (context, index) {
                      final child = widget.availableChildren[index];
                      final isSelected = selectionProvider.isSelected(child);

                      return Column(
                        children: [
                          CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggleChild(child),
                            title: Row(
                              children: [
                                if (child['photo'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(
                                        child['photo'],
                                      ),
                                      onBackgroundImageError: (_, _) {},
                                      child: Icon(
                                        Icons.person,
                                        color: Config.accent.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Config.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Config.accent,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child['name'] ?? 'Tanpa Nama',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Config.textHead,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${child['id']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Config.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            activeColor: Config.primary,
                            checkColor: Colors.white,
                            tileColor: isSelected
                                ? Config.primary.withValues(alpha: 0.1)
                                : null,
                          ),
                          if (index < widget.availableChildren.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),
              if (selectionProvider.selectedChildren.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Anak-Anak Terpilih:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Config.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectionProvider.selectedChildren.map((child) {
                    return Chip(
                      avatar: child['photo'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(child['photo']),
                              onBackgroundImageError: (_, _) {},
                            )
                          : null,
                      label: Text(
                        child['name'] ?? 'Tanpa Nama',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Config.primary,
                      onDeleted: () => _toggleChild(child),
                      deleteIconColor: Colors.white,
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
