import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// Widget for editing a single line of a lead sheet
/// Shows chords above lyrics and allows clicking to add/edit chords
class LeadSheetLineEditor extends StatefulWidget {
  final LeadSheetLine line;
  final int lineIndex;
  final ValueChanged<LeadSheetLine> onLineChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onAddLineBelow;
  final TextStyle? lyricsStyle;
  final TextStyle? chordStyle;

  const LeadSheetLineEditor({
    super.key,
    required this.line,
    required this.lineIndex,
    required this.onLineChanged,
    this.onDelete,
    this.onAddLineBelow,
    this.lyricsStyle,
    this.chordStyle,
  });

  @override
  State<LeadSheetLineEditor> createState() => _LeadSheetLineEditorState();
}

class _LeadSheetLineEditorState extends State<LeadSheetLineEditor> {
  late TextEditingController _lyricsController;
  final FocusNode _lyricsFocusNode = FocusNode();
  int? _selectedChordPosition;
  bool _isEditingChord = false;
  final TextEditingController _chordController = TextEditingController();

  // Character width for monospace positioning
  static const double _charWidth = 10.0;
  static const double _lineHeight = 24.0;

  @override
  void initState() {
    super.initState();
    _lyricsController = TextEditingController(text: widget.line.lyrics);
  }

  @override
  void didUpdateWidget(LeadSheetLineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.lyrics != widget.line.lyrics) {
      _lyricsController.text = widget.line.lyrics;
    }
  }

  @override
  void dispose() {
    _lyricsController.dispose();
    _lyricsFocusNode.dispose();
    _chordController.dispose();
    super.dispose();
  }

  void _onLyricsChanged(String value) {
    widget.onLineChanged(widget.line.copyWith(lyrics: value));
  }

  void _onChordAreaTap(TapDownDetails details) {
    // Calculate which character position was clicked
    final position = (details.localPosition.dx / _charWidth).floor();
    final maxPosition = widget.line.lyrics.length;
    final clampedPosition = position.clamp(0, maxPosition);

    // Check if there's already a chord at this position
    final existingChord = widget.line.chords.where(
      (c) => c.position == clampedPosition,
    ).firstOrNull;

    setState(() {
      _selectedChordPosition = clampedPosition;
      _isEditingChord = true;
      _chordController.text = existingChord?.symbol ?? '';
    });
  }

  void _submitChord() {
    if (_selectedChordPosition == null) return;

    final symbol = _chordController.text.trim();
    LeadSheetLine updatedLine;

    if (symbol.isEmpty) {
      // Remove chord if empty
      updatedLine = widget.line.removeChordAt(_selectedChordPosition!);
    } else {
      // Check if chord exists at this position
      final existingChord = widget.line.chords
          .where((c) => c.position == _selectedChordPosition)
          .firstOrNull;

      if (existingChord != null) {
        // Update existing chord
        updatedLine = widget.line.updateChordAt(_selectedChordPosition!, symbol);
      } else {
        // Add new chord
        updatedLine = widget.line.addChord(
          Chord(symbol: symbol, position: _selectedChordPosition!),
        );
      }
    }

    widget.onLineChanged(updatedLine);
    _cancelChordEdit();
  }

  void _cancelChordEdit() {
    setState(() {
      _selectedChordPosition = null;
      _isEditingChord = false;
      _chordController.clear();
    });
  }

  void _deleteChordAt(int position) {
    widget.onLineChanged(widget.line.removeChordAt(position));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chordStyle = widget.chordStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        );
    final lyricsStyle = widget.lyricsStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chord line (clickable area)
        GestureDetector(
          onTapDown: _onChordAreaTap,
          child: Container(
            constraints: BoxConstraints(
              minHeight: _lineHeight,
              minWidth: (widget.line.lyrics.length + 10) * _charWidth,
            ),
            child: Stack(
              children: [
                // Background indicator on hover
                Container(
                  height: _lineHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Render chords
                ...widget.line.chords.map((chord) => Positioned(
                  left: chord.position * _charWidth,
                  child: _ChordChip(
                    chord: chord,
                    style: chordStyle!,
                    isSelected: _selectedChordPosition == chord.position,
                    onTap: () {
                      setState(() {
                        _selectedChordPosition = chord.position;
                        _isEditingChord = true;
                        _chordController.text = chord.symbol;
                      });
                    },
                    onDelete: () => _deleteChordAt(chord.position),
                  ),
                )),
                // Show position indicator when editing
                if (_isEditingChord && _selectedChordPosition != null)
                  Positioned(
                    left: _selectedChordPosition! * _charWidth,
                    child: Container(
                      width: 2,
                      height: _lineHeight,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Chord input field (shown when editing)
        if (_isEditingChord)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _chordController,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Chord (e.g., Am)',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    style: chordStyle,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Ga-g#bmajdimsusMM0-9/]')),
                    ],
                    onSubmitted: (_) => _submitChord(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.check, size: 18),
                  onPressed: _submitChord,
                  tooltip: 'Add chord',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _cancelChordEdit,
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ),
        // Lyrics line
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lyricsController,
                focusNode: _lyricsFocusNode,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Enter lyrics...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: lyricsStyle,
                onChanged: _onLyricsChanged,
              ),
            ),
            // Line actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: theme.hintColor),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_below',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('Add line below'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18),
                      SizedBox(width: 8),
                      Text('Delete line'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  widget.onDelete?.call();
                } else if (value == 'add_below') {
                  widget.onAddLineBelow?.call();
                }
              },
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// A chip displaying a chord symbol
class _ChordChip extends StatelessWidget {
  final Chord chord;
  final TextStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChordChip({
    required this.chord,
    required this.style,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(chord.symbol, style: style),
      ),
    );
  }
}
