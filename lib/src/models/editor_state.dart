class VideoSegment {
  VideoSegment({required this.start, required this.end, this.deleted = false});

  double start; // seconds
  double end; // seconds
  bool deleted;

  double get duration => (end - start).clamp(0, double.infinity);

  VideoSegment copy() => VideoSegment(start: start, end: end, deleted: deleted);
}

class EditorState {
  EditorState({required this.sourcePath, required this.durationSeconds});

  String? sourcePath;
  double durationSeconds;
  List<VideoSegment> segments = <VideoSegment>[];
  int selectedIndex = 0;
  List<dynamic> timelineThumbnails = <dynamic>[]; // files

  bool get hasSource => sourcePath != null;

  List<VideoSegment> get playableSegments =>
      segments.where((VideoSegment s) => !s.deleted && s.duration > 0).toList();

  factory EditorState.empty() => EditorState(sourcePath: null, durationSeconds: 0);

  factory EditorState.fromSingleSource(String path, double duration) {
    final EditorState s = EditorState(sourcePath: path, durationSeconds: duration);
    s.segments = <VideoSegment>[VideoSegment(start: 0, end: duration)];
    s.selectedIndex = 0;
    return s;
  }

  void splitAt(double t) {
    if (segments.isEmpty) return;
    final int idx = _segmentIndexAt(t);
    if (idx < 0) return;
    final VideoSegment seg = segments[idx];
    if (t <= seg.start + 0.01 || t >= seg.end - 0.01) return; 
    final VideoSegment left = VideoSegment(start: seg.start, end: t, deleted: seg.deleted);
    final VideoSegment right = VideoSegment(start: t, end: seg.end, deleted: seg.deleted);
    segments
      ..removeAt(idx)
      ..insertAll(idx, <VideoSegment>[left, right]);
    selectedIndex = idx;
  }

  void toggleDeleteSelected() {
    if (segments.isEmpty) return;
    if (selectedIndex < 0 || selectedIndex >= segments.length) return;
    segments[selectedIndex].deleted = !segments[selectedIndex].deleted;
  }

  int _segmentIndexAt(double t) {
    for (int i = 0; i < segments.length; i++) {
      final VideoSegment s = segments[i];
      if (t >= s.start && t <= s.end) return i;
    }
    return -1;
  }
}



