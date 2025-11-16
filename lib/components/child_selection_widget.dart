import 'package:flutter/material.dart';
import 'package:family_tree_app/config/config.dart';

class ChildSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> availableChildren;
  final List<Map<String, dynamic>>? selectedChildren;
  final Function(List<Map<String, dynamic>>) onChildrenSelected;

  const ChildSelectionWidget({
    Key? key,
    required this.availableChildren,
    this.selectedChildren,
    required this.onChildrenSelected,
  }) : super(key: key);

  @override
  State<ChildSelectionWidget> createState() => _ChildSelectionWidgetState();
}

class _ChildSelectionWidgetState extends State<ChildSelectionWidget> {
  late List<Map<String, dynamic>> _selectedChildren;

  @override
  void initState() {
    super.initState();
    _selectedChildren = widget.selectedChildren ?? [];
  }

  void _toggleChild(Map<String, dynamic> child) {
    setState(() {
      final existingIndex = _selectedChildren.indexWhere(
        (c) => c['id'] == child['id'],
      );

      if (existingIndex >= 0) {
        _selectedChildren.removeAt(existingIndex);
      } else {
        _selectedChildren.add(child);
      }
    });
    widget.onChildrenSelected(_selectedChildren);
  }

  @override
  Widget build(BuildContext context) {
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
                final isSelected = _selectedChildren.any(
                  (c) => c['id'] == child['id'],
                );

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
                                backgroundImage: NetworkImage(child['photo']),
                                onBackgroundImageError: (_, __) {},
                                child: Icon(
                                  Icons.person,
                                  color: Config.accent.withValues(alpha: 0.5),
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
                                child: Icon(Icons.person, color: Config.accent),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
        if (_selectedChildren.isNotEmpty) ...[
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
            children: _selectedChildren.map((child) {
              return Chip(
                avatar: child['photo'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(child['photo']),
                        onBackgroundImageError: (_, __) {},
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
  }
}
