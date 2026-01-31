/// Represents a chord placed above lyrics at a specific position
class Chord {
  final String symbol; // e.g., "G", "Am", "C#m7", "Fmaj7"
  final int position;  // Character position in the lyrics line

  const Chord({
    required this.symbol,
    required this.position,
  });

  Chord copyWith({String? symbol, int? position}) {
    return Chord(
      symbol: symbol ?? this.symbol,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'position': position,
  };

  factory Chord.fromJson(Map<String, dynamic> json) => Chord(
    symbol: json['symbol'] as String,
    position: json['position'] as int,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chord &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          position == other.position;

  @override
  int get hashCode => symbol.hashCode ^ position.hashCode;

  @override
  String toString() => 'Chord($symbol @ $position)';
}
