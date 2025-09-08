import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class ThumbnailService {
  static Future<void> generateTimelineThumbnails({
    required String videoPath,
    required double durationSeconds,
    required void Function(List<File> files) onGenerated,
    int targetCount = 30,
  }) async {
    final Directory temp = await getTemporaryDirectory();
    final String dir = p.join(temp.path, 'thumbs_${DateTime.now().millisecondsSinceEpoch}');
    await Directory(dir).create(recursive: true);

    final List<File> results = <File>[];
    final int count = durationSeconds.isFinite && durationSeconds > 0
        ? targetCount
        : 10;
    for (int i = 0; i < count; i++) {
      final double t = (durationSeconds * i) / count;
      final String? path = await vt.VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        timeMs: (t * 1000).toInt(),
        quality: 70,
        thumbnailPath: dir,
      );
      if (path != null) {
        results.add(File(path));
      }
    }
    onGenerated(results);
  }
}




