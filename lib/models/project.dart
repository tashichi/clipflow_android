class VideoSegment {
  final int id;
  final String uri;
  final DateTime timestamp;
  final String cameraPosition;
  int order;

  VideoSegment({
    required this.id,
    required this.uri,
    required this.timestamp,
    required this.cameraPosition,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uri': uri,
        'timestamp': timestamp.toIso8601String(),
        'cameraPosition': cameraPosition,
        'order': order,
      };

  factory VideoSegment.fromJson(Map<String, dynamic> json) => VideoSegment(
        id: json['id'],
        uri: json['uri'],
        timestamp: DateTime.parse(json['timestamp']),
        cameraPosition: json['cameraPosition'],
        order: json['order'],
      );
}

class Project {
  final int id;
  String name;
  List<VideoSegment> segments;
  final DateTime createdAt;
  DateTime lastModified;

  Project({
    required this.id,
    required this.name,
    required this.segments,
    required this.createdAt,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'segments': segments.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        segments: (json['segments'] as List)
            .map((s) => VideoSegment.fromJson(s))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        lastModified: DateTime.parse(json['lastModified']),
      );
}