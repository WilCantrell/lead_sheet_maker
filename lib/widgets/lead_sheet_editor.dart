import 'package:flutter/material.dart';
import '../models/models.dart';
import 'lead_sheet_line_editor.dart';

/// Full lead sheet editor with title, metadata, and all lines
class LeadSheetEditor extends StatefulWidget {
  final LeadSheet leadSheet;
  final ValueChanged<LeadSheet> onChanged;

  const LeadSheetEditor({
    super.key,
    required this.leadSheet,
    required this.onChanged,
  });

  @override
  State<LeadSheetEditor> createState() => _LeadSheetEditorState();
}

class _LeadSheetEditorState extends State<LeadSheetEditor> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _keyController;
  late TextEditingController _tempoController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.leadSheet.title);
    _artistController = TextEditingController(text: widget.leadSheet.artist);
    _keyController = TextEditingController(text: widget.leadSheet.key ?? '');
    _tempoController = TextEditingController(text: widget.leadSheet.tempo ?? '');
  }

  @override
  void didUpdateWidget(LeadSheetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leadSheet.id != widget.leadSheet.id) {
      _titleController.text = widget.leadSheet.title;
      _artistController.text = widget.leadSheet.artist;
      _keyController.text = widget.leadSheet.key ?? '';
      _tempoController.text = widget.leadSheet.tempo ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _keyController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  void _updateMetadata() {
    widget.onChanged(widget.leadSheet.copyWith(
      title: _titleController.text,
      artist: _artistController.text,
      key: _keyController.text.isEmpty ? null : _keyController.text,
      tempo: _tempoController.text.isEmpty ? null : _tempoController.text,
    ));
  }

  void _updateLine(int index, LeadSheetLine line) {
    widget.onChanged(widget.leadSheet.updateLine(index, line));
  }

  void _deleteLine(int index) {
    if (widget.leadSheet.lines.length > 1) {
      widget.onChanged(widget.leadSheet.removeLine(index));
    }
  }

  void _addLineAt(int index) {
    widget.onChanged(widget.leadSheet.addLine(
      const LeadSheetLine(lyrics: ''),
      index,
    ));
  }

  void _addLineAtEnd() {
    widget.onChanged(widget.leadSheet.addLine(
      const LeadSheetLine(lyrics: ''),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and metadata section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    style: theme.textTheme.headlineSmall,
                    onChanged: (_) => _updateMetadata(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artist',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateMetadata(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keyController,
                          decoration: const InputDecoration(
                            labelText: 'Key',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., G, Am',
                          ),
                          onChanged: (_) => _updateMetadata(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tempoController,
                          decoration: const InputDecoration(
                            labelText: 'Tempo',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 120 BPM',
                          ),
                          onChanged: (_) => _updateMetadata(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click above any lyrics to add a chord. Click a chord to edit or delete it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lines section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lyrics & Chords', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addLineAtEnd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Line'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lines
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.leadSheet.lines.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.music_note,
                                size: 48, color: theme.hintColor),
                            const SizedBox(height: 8),
                            Text(
                              'No lyrics yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addLineAtEnd,
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Line'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...widget.leadSheet.lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LeadSheetLineEditor(
                          key: ValueKey('line_$index'),
                          line: line,
                          lineIndex: index,
                          onLineChanged: (updatedLine) =>
                              _updateLine(index, updatedLine),
                          onDelete: () => _deleteLine(index),
                          onAddLineBelow: () => _addLineAt(index + 1),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
