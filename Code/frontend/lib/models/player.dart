class Player {
  final String id;
  final String name;
  final String? photoURL;  // Add this field
  final int score;
  final bool isDrawing;
  final bool isCreator;  // Add creator flag

  Player({
    required this.id,
    required this.name,
    this.photoURL,  // Add this parameter
    this.score = 0,
    this.isDrawing = false,
    this.isCreator = false,  // Add creator flag
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      photoURL: json['photoURL'] as String?,  // Add this field
      score: json['score'] as int? ?? 0,
      isDrawing: json['isDrawing'] as bool? ?? false,
      isCreator: json['isCreator'] as bool? ?? false,  // Add creator flag
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoURL': photoURL,  // Add this field
      'score': score,
      'isDrawing': isDrawing,
      'isCreator': isCreator,  // Add creator flag
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? photoURL,  // Add this parameter
    int? score,
    bool? isDrawing,
    bool? isCreator,  // Add creator flag
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,  // Add this field
      score: score ?? this.score,
      isDrawing: isDrawing ?? this.isDrawing,
      isCreator: isCreator ?? this.isCreator,  // Add creator flag
    );
  }
}
