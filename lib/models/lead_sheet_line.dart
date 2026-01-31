import 'chord.dart';

/// Represents a single line of a lead sheet: lyrics with chords above
class LeadSheetLine {
  final String lyrics;
  final List<Chord> chords;

  const LeadSheetLine({
    required this.lyrics,
    this.chords = const [],
  });

  LeadSheetLine copyWith({String? lyrics, List<Chord>? chords}) {
    return LeadSheetLine(
      lyrics: lyrics ?? this.lyrics,
      chords: chords ?? this.chords,
    );
  }

  /// Add a chord at the specified position
  LeadSheetLine addChord(Chord chord) {
    final newChords = List<Chord>.from(chords)
      ..add(chord)
      ..sort((a, b) => a.position.compareTo(b.position));
    return copyWith(chords: newChords);
  }

  /// Remove a chord at the specified position
  LeadSheetLine removeChordAt(int position) {
    final newChords = chords.where((c) => c.position != position).toList();
    return copyWith(chords: newChords);
  }

  /// Update a chord at the specified position
  LeadSheetLine updateChordAt(int position, String newSymbol) {
    final newChords = chords.map((c) {
      if (c.position == position) {
        return c.copyWith(symbol: newSymbol);
      }
      return c;
    }).toList();
    return copyWith(chords: newChords);
  }

  /// Move a chord from one position to another
  LeadSheetLine moveChord(int fromPosition, int toPosition) {
    final chord = chords.firstWhere(
      (c) => c.position == fromPosition,
      orElse: () => throw StateError('No chord at position $fromPosition'),
    );
    final newChords = chords
        .where((c) => c.position != fromPosition)
        .toList()
      ..add(chord.copyWith(position: toPosition))
      ..sort((a, b) => a.position.compareTo(b.position));
    return copyWith(chords: newChords);
  }

  /// Generate the chord line as a string with proper spacing
  String get chordLine {
    if (chords.isEmpty) return '';
    
    final buffer = StringBuffer();
    var currentPos = 0;
    
    for (final chord in chords) {
      // Add spaces to reach the chord position
      while (currentPos < chord.position) {
        buffer.write(' ');
        currentPos++;
      }
      buffer.write(chord.symbol);
      currentPos += chord.symbol.length;
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'lyrics': lyrics,
    'chords': chords.map((c) => c.toJson()).toList(),
  };

  factory LeadSheetLine.fromJson(Map<String, dynamic> json) => LeadSheetLine(
    lyrics: json['lyrics'] as String,
    chords: (json['chords'] as List<dynamic>)
        .map((c) => Chord.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  @override
  String toString() => '$chordLine\n$lyrics';
}
