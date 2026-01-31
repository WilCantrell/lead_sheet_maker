import 'lead_sheet_line.dart';

/// Represents a complete lead sheet with title, artist, and lines
class LeadSheet {
  final String id;
  final String title;
  final String artist;
  final String? key;
  final String? tempo;
  final List<LeadSheetLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeadSheet({
    required this.id,
    required this.title,
    this.artist = '',
    this.key,
    this.tempo,
    this.lines = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  LeadSheet copyWith({
    String? id,
    String? title,
    String? artist,
    String? key,
    String? tempo,
    List<LeadSheetLine>? lines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadSheet(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      tempo: tempo ?? this.tempo,
      lines: lines ?? this.lines,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add a new line at the specified index (or at the end)
  LeadSheet addLine(LeadSheetLine line, [int? index]) {
    final newLines = List<LeadSheetLine>.from(lines);
    if (index != null && index >= 0 && index <= newLines.length) {
      newLines.insert(index, line);
    } else {
      newLines.add(line);
    }
    return copyWith(lines: newLines);
  }

  /// Update a line at the specified index
  LeadSheet updateLine(int index, LeadSheetLine line) {
    if (index < 0 || index >= lines.length) {
      throw RangeError('Index $index out of range');
    }
    final newLines = List<LeadSheetLine>.from(lines);
    newLines[index] = line;
    return copyWith(lines: newLines);
  }

  /// Remove a line at the specified index
  LeadSheet removeLine(int index) {
    if (index < 0 || index >= lines.length) {
      throw RangeError('Index $index out of range');
    }
    final newLines = List<LeadSheetLine>.from(lines)..removeAt(index);
    return copyWith(lines: newLines);
  }

  /// Export as plain text
  String toPlainText() {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(title);
    if (artist.isNotEmpty) buffer.writeln('by $artist');
    if (key != null) buffer.write('Key: $key  ');
    if (tempo != null) buffer.write('Tempo: $tempo');
    if (key != null || tempo != null) buffer.writeln();
    buffer.writeln();
    
    // Lines
    for (final line in lines) {
      if (line.chords.isNotEmpty) {
        buffer.writeln(line.chordLine);
      }
      buffer.writeln(line.lyrics);
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'key': key,
    'tempo': tempo,
    'lines': lines.map((l) => l.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LeadSheet.fromJson(Map<String, dynamic> json) => LeadSheet(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String? ?? '',
    key: json['key'] as String?,
    tempo: json['tempo'] as String?,
    lines: (json['lines'] as List<dynamic>)
        .map((l) => LeadSheetLine.fromJson(l as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  @override
  String toString() => 'LeadSheet($title by $artist, ${lines.length} lines)';
}
