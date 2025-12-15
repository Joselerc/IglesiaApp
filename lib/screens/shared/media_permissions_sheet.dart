import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MediaPermissionsSheet extends StatefulWidget {
  final List<DocumentSnapshot> members;
  final Set<String> initialSelected;
  final Set<String> lockedIds;
  final String adminLabel;
  final String title;
  final String selectAllLabel;
  final String deselectAllLabel;
  final String searchHint;
  final String saveLabel;
  final String emptyLabel;
  final void Function(Set<String>) onSave;

  const MediaPermissionsSheet({
    super.key,
    required this.members,
    required this.initialSelected,
    required this.lockedIds,
    required this.adminLabel,
    required this.title,
    required this.selectAllLabel,
    required this.deselectAllLabel,
    required this.searchHint,
    required this.saveLabel,
    required this.emptyLabel,
    required this.onSave,
  });

  @override
  State<MediaPermissionsSheet> createState() => _MediaPermissionsSheetState();
}

class _MediaPermissionsSheetState extends State<MediaPermissionsSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected)..addAll(widget.lockedIds);
  }

  List<DocumentSnapshot> get _filteredMembers {
    if (_query.isEmpty) return widget.members;
    final lower = _query.toLowerCase();
    return widget.members.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? data['displayName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return name.contains(lower) || email.contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.members.length && widget.members.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected = widget.members.map((e) => e.id).toSet();
                      }
                    });
                  },
                  child: Text(allSelected ? widget.deselectAllLabel : widget.selectAllLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _filteredMembers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        widget.emptyLabel,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = _filteredMembers[index];
                        final data = member.data() as Map<String, dynamic>;
                        final name = data['name'] ?? data['displayName'] ?? 'Usuario';
                        final photoUrl = data['photoUrl'] as String? ?? '';
                        final selected = _selected.contains(member.id);
                        final isLocked = widget.lockedIds.contains(member.id);

                        return CheckboxListTile(
                          value: selected,
                          onChanged: isLocked
                              ? null
                              : (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selected.add(member.id);
                                    } else {
                                      _selected.remove(member.id);
                                    }
                                  });
                                },
                          title: Text(name),
                          secondary: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty
                                ? Text(
                                    name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                  )
                                : null,
                          ),
                          subtitle: isLocked ? Text(widget.adminLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12)) : null,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_selected);
                  Navigator.of(context).pop();
                },
                child: Text(widget.saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
