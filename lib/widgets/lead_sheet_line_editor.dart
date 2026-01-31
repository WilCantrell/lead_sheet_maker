import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// Widget for editing a single line of a lead sheet
/// Shows chords above lyrics and allows clicking to add/edit chords
/// Supports drag-and-drop repositioning of chords
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
  
  // Drag state
  int? _draggedChordPosition;
  int? _dragTargetPosition;

  // Character width for monospace positioning
  static const double _charWidth = 10.0;
  static const double _lineHeight = 28.0;

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

  int _positionFromOffset(double dx) {
    final position = (dx / _charWidth).floor();
    final maxPosition = widget.line.lyrics.length;
    return position.clamp(0, maxPosition);
  }

  void _onChordAreaTap(TapDownDetails details) {
    if (_draggedChordPosition != null) return; // Don't handle taps during drag
    
    final clampedPosition = _positionFromOffset(details.localPosition.dx);

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

  void _onDragStart(int chordPosition) {
    setState(() {
      _draggedChordPosition = chordPosition;
      _dragTargetPosition = chordPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double containerLeft) {
    if (_draggedChordPosition == null) return;
    
    final newPosition = _positionFromOffset(details.globalPosition.dx - containerLeft);
    if (newPosition != _dragTargetPosition) {
      setState(() {
        _dragTargetPosition = newPosition;
      });
    }
  }

  void _onDragEnd() {
    if (_draggedChordPosition != null && _dragTargetPosition != null) {
      if (_draggedChordPosition != _dragTargetPosition) {
        // Check if there's already a chord at the target position
        final existingAtTarget = widget.line.chords
            .where((c) => c.position == _dragTargetPosition)
            .firstOrNull;
        
        if (existingAtTarget == null) {
          // Move the chord
          widget.onLineChanged(
            widget.line.moveChord(_draggedChordPosition!, _dragTargetPosition!),
          );
        }
      }
    }
    
    setState(() {
      _draggedChordPosition = null;
      _dragTargetPosition = null;
    });
  }

  void _onDragCancel() {
    setState(() {
      _draggedChordPosition = null;
      _dragTargetPosition = null;
    });
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
        // Chord line (clickable area with drag support)
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: _onChordAreaTap,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: _lineHeight,
                  minWidth: (widget.line.lyrics.length + 10) * _charWidth,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background indicator
                    Container(
                      height: _lineHeight,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Drop target indicator during drag
                    if (_dragTargetPosition != null && _draggedChordPosition != null)
                      Positioned(
                        left: _dragTargetPosition! * _charWidth,
                        child: Container(
                          width: 2,
                          height: _lineHeight,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    // Render chords
                    ...widget.line.chords.map((chord) {
                      final isDragging = _draggedChordPosition == chord.position;
                      
                      return Positioned(
                        left: chord.position * _charWidth,
                        child: _DraggableChordChip(
                          chord: chord,
                          style: chordStyle!,
                          isSelected: _selectedChordPosition == chord.position,
                          isDragging: isDragging,
                          onTap: () {
                            setState(() {
                              _selectedChordPosition = chord.position;
                              _isEditingChord = true;
                              _chordController.text = chord.symbol;
                            });
                          },
                          onDelete: () => _deleteChordAt(chord.position),
                          onDragStart: () => _onDragStart(chord.position),
                          onDragUpdate: (details) {
                            final renderBox = context.findRenderObject() as RenderBox;
                            final containerLeft = renderBox.localToGlobal(Offset.zero).dx;
                            _onDragUpdate(details, containerLeft);
                          },
                          onDragEnd: _onDragEnd,
                          onDragCancel: _onDragCancel,
                        ),
                      );
                    }),
                    // Show position indicator when editing (not dragging)
                    if (_isEditingChord && _selectedChordPosition != null && _draggedChordPosition == null)
                      Positioned(
                        left: _selectedChordPosition! * _charWidth,
                        child: Container(
                          width: 2,
                          height: _lineHeight,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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
                if (_selectedChordPosition != null &&
                    widget.line.chords.any((c) => c.position == _selectedChordPosition))
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                    onPressed: () {
                      _deleteChordAt(_selectedChordPosition!);
                      _cancelChordEdit();
                    },
                    tooltip: 'Delete chord',
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
                decoration: const InputDecoration(
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

/// A draggable chip displaying a chord symbol
class _DraggableChordChip extends StatelessWidget {
  final Chord chord;
  final TextStyle style;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;

  const _DraggableChordChip({
    required this.chord,
    required this.style,
    required this.isSelected,
    required this.isDragging,
    required this.onTap,
    required this.onDelete,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragCancel,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDragging
                ? theme.colorScheme.primaryContainer
                : isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDragging
                  ? theme.colorScheme.primary
                  : isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(77),
              width: isDragging || isSelected ? 2 : 1,
            ),
            boxShadow: isDragging
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            chord.symbol,
            style: style.copyWith(
              color: isDragging || isSelected
                  ? theme.colorScheme.primary
                  : style.color,
            ),
          ),
        ),
      ),
    );
  }
}
